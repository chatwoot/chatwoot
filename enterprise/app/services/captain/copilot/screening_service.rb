class Captain::Copilot::ScreeningService
  include Captain::Copilot::Tracing

  MODEL = 'jev-latest'.freeze
  # The review model confirms every conversation that passes, so screening favours recall. Jev scores borderline
  # matches low: on a 45-conversation billing sample, 0.3 kept 3 of the 6 matches the review model found and 0.1 kept 5.
  THRESHOLD = 0.1
  # Longer conversations skip screening: evidence before the window would be screened out unseen, while the review model
  # can read further back.
  WINDOW = 20
  # Jev reads every message whole, within the budget Captain::ConversationTranscript gives Jev. More text skips screening
  # for the same reason, because a cut message could hide the request.
  CHARACTER_BUDGET = Captain::ConversationTranscript::TOKEN_BUDGET * Captain::ConversationTranscript::CHARACTERS_PER_TOKEN
  # A rejected key or a rate limit fails every call the same way, so screening stops for the rest of the batch.
  STOP_STATUSES = [401, 403, 429].freeze
  def self.available?
    Captain::JevClient.api_key.present?
  end

  def initialize(run, token)
    @run = run
    @token = token
    @client = Captain::JevClient.new(account_id: run.account_id, feature: 'copilot_screening')
  end

  # Screens conversations that have no finding yet against the run's question and returns the ones to review.
  def screen(conversations)
    return conversations if @run.question.blank?

    findings = @run.findings.where(conversation_id: conversations.map(&:id))
    screened_ids = findings.pluck(:conversation_id).to_set
    # A batch can hold only conversations screened earlier, such as ones waiting for a deep review.
    unscreened = conversations.reject { |conversation| screened_ids.include?(conversation.id) }
    screen_each(unscreened) if unscreened.any?
    kept_ids = findings.where.not(status: :screened_out).pluck(:conversation_id).to_set
    conversations.select { |conversation| kept_ids.include?(conversation.id) }
  end

  private

  # Each score is saved as it arrives, so a job stopped partway keeps the Jev calls it already paid for.
  def screen_each(conversations)
    params = { account_id: @run.account_id, feature_name: 'copilot_screening', model: MODEL,
               metadata: { run_id: @run.id, conversation_ids: conversations.map(&:id) } }
    with_copilot_trace('llm.captain.copilot_screening', params, turn: @run.turn, input: @run.question) do
      conversations.to_h do |conversation|
        # A batch of Jev calls can outlast the lease, and turning workflows off should stop it between calls.
        @run.renew_lease(@token)
        @run.ensure_can_continue!
        value = score(conversation) unless @stopped
        record(conversation.id, value)
        [conversation.id, value]
      end
    end
  end

  # No score keeps the conversation for the review model: it was too long to screen, the screen failed, or screening
  # stopped. Float raises ArgumentError or TypeError when Jev returns no number.
  def score(conversation)
    messages = transcript(conversation)
    return unless messages

    state = { conversation: { messages: messages } }
    question = { type: 'noul', instructions: { question: @run.question, evidence: Captain::PromptRenderer.render('copilot_screening_evidence') } }
    body = Captain::JevClient.request_body(model: MODEL, state: state, questions: { match: question })
    response = @client.call(body: body)
    record_cost(response.dig('usage', 'cost'))
    Float(response.dig('answers', 'match', 'noul'))
  rescue Captain::JevClient::HTTPError, Faraday::Error, JSON::ParserError, ArgumentError, TypeError => e
    record_cost(nil) unless response
    ChatwootExceptionTracker.new(e, account: @run.account).capture_exception
    @stopped = e.is_a?(Captain::JevClient::HTTPError) && STOP_STATUSES.include?(e.status)
    nil
  end

  def record_cost(amount)
    @run.record_cost!(amount)
  rescue StandardError => e
    Rails.logger.warn "Failed to record Jev screening cost: #{e.message}"
  end

  # The messages the review model reads, up to as_of.
  def transcript(conversation)
    messages = Captain::Copilot::ReadableMessages.scope(conversation.messages, as_of: @run.as_of)
                                                 .reorder(created_at: :desc, id: :desc).limit(WINDOW + 1).to_a
    return if messages.size > WINDOW

    transcript = messages.reverse.map do |message|
      { sender: Captain::Copilot::ReadableMessages.sender_role(message), private: message.private?, text: message.content_for_llm.to_s }
    end
    transcript if transcript.sum { |entry| entry[:text].size } <= CHARACTER_BUDGET
  end

  def record(conversation_id, score)
    status = score && score < THRESHOLD ? :screened_out : :awaiting_review
    @run.with_lease(@token) { @run.findings.create!(conversation_id: conversation_id, status: status, screening_score: score) }
  end
end
