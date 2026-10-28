class Captain::Copilot::ReviewService < Llm::BaseAiService
  include Captain::Copilot::Tracing
  include Captain::ChatGenerationRecorder

  attr_reader :llm_protocol

  # A long conversation is read from both ends: the opening says why the customer reached out, and the newest messages
  # show where it stands. The deep pass runs when the first one asks for more history.
  # Each pass shares one character budget, 1,500 per message on average, so short messages leave room for long ones.
  FIRST_PASS = { opening: 3, latest: 5, characters: 12_000 }.freeze
  DEEP_PASS = { opening: 10, latest: 40, characters: 75_000 }.freeze

  def initialize(run)
    @run = run
    super(feature: 'copilot_workflows', account: run.account)
  end

  # Reviews one conversation per model call, so a response can never omit or mix up conversations.
  def review(conversation, deep: false)
    @run.ensure_can_continue!
    evidence = conversation_for_review(conversation, deep)
    prompt = { product: @run.copilot_thread.assistant.config['product_name'], request: @run.request, question: @run.question,
               criteria: @run.criteria, as_of: @run.as_of.iso8601, conversation: evidence }.compact.to_json
    input = { conversation_id: conversation.id, deep: deep }
    content = with_copilot_trace('llm.captain.copilot_review', trace_params(conversation), turn: @run.turn, input: input) do
      build_chat.ask(prompt).content
    end
    parse_result(JSON.parse(sanitize_json_response(content)), evidence, deep)
  end

  private

  def trace_params(conversation)
    { account_id: @run.account_id, feature_name: 'copilot_review', model: model, metadata: { run_id: @run.id, conversation_id: conversation.id } }
  end

  def build_chat
    options = Captain::ResponsesConfig.options(model: @model, temperature: @temperature, feature: @llm_feature)
    # ChatGenerationRecorder reads the protocol to record model, tokens and cost on the generation.
    @llm_protocol = options[:protocol]
    llm = chat(model: @model, **options).with_instructions(Captain::PromptRenderer.render('copilot_review'))
                                        .with_schema(Captain::Copilot::ReviewResponseSchema)
    llm.after_message do |message|
      record_llm_generation(llm, message)
      # The credit is charged once for the turn's answer, not for each conversation reviewed.
      record_generation_cost(@run, message)
    end
    llm
  end

  def conversation_for_review(conversation, deep)
    window = deep ? DEEP_PASS : FIRST_PASS
    messages, omitted = window_messages(conversation, window)
    contents = messages.map { |message| message.content_for_llm.to_s }
    excerpts = contents.zip(shares(contents.map(&:size), window[:characters])).map { |content, share| excerpt(content, share) }
    { id: conversation.id, display_id: conversation.display_id, status: conversation.status,
      priority: conversation.priority, assignee_id: conversation.assignee_id, last_activity_at: conversation.last_activity_at,
      history_truncated: omitted.positive?, omitted_messages: omitted,
      messages: messages.zip(contents, excerpts).map { |message, content, text| message_for_review(message, text, text != content) } }
  end

  # The oldest and newest of the messages screening also reads. reorder, because Message's default scope sorts oldest
  # first and order would only add a second sort key.
  def window_messages(conversation, window)
    scope = Captain::Copilot::ReadableMessages.scope(conversation.messages, as_of: @run.as_of)
    opening = scope.reorder(created_at: :asc, id: :asc).limit(window[:opening]).to_a
    latest = scope.reorder(created_at: :desc, id: :desc).limit(window[:latest]).to_a.reverse
    messages = (opening + latest).uniq(&:id)
    [messages, scope.count - messages.size]
  end

  # Splits the budget from the shortest message up: each takes its full length or an equal share of what is left, so
  # one pasted log can't crowd out the other messages.
  def shares(sizes, budget)
    remaining = budget
    shares = Array.new(sizes.size)
    sizes.each_with_index.sort_by(&:first).each_with_index do |(size, index), position|
      shares[index] = [size, remaining / (sizes.size - position)].min
      remaining -= shares[index]
    end
    shares
  end

  # A request often comes after a greeting or a pasted report, or before a signature, so a long message keeps both ends.
  def excerpt(content, limit)
    return content if content.size <= limit

    half = limit / 2
    "#{content.first(half)}\n[... #{content.size - (2 * half)} characters cut ...]\n#{content.last(half)}"
  end

  def message_for_review(message, content, truncated)
    { id: message.id, at: message.created_at, type: message.message_type, private: message.private?,
      sender: Captain::Copilot::ReadableMessages.sender_role(message), content: content, content_truncated: truncated }
  end

  def parse_result(row, evidence, deep)
    reviewed_ids = evidence[:messages].pluck(:id)
    evidence_ids = row['evidence_message_ids']
    validate_result!(row, evidence_ids, reviewed_ids)
    # The reviewer sometimes rules a conversation out on text it never saw, so a first-pass no on a cut message goes to
    # the deep pass, which has room for more of it.
    more = row['needs_more_history'] || (!deep && !row['matched'] && evidence[:messages].any? { |message| message[:content_truncated] })
    { status: more ? :needs_more_history : :reviewed, matched: more ? false : row['matched'],
      category: row['category'].to_s.first(80), reason: row['reason'].to_s.first(500), evidence_message_ids: evidence_ids,
      reviewed_message_ids: reviewed_ids, history_truncated: evidence[:history_truncated] }
  end

  def validate_result!(row, evidence_ids, reviewed_ids)
    unless row.values_at('matched', 'needs_more_history').all? { |value| [true, false].include?(value) }
      raise ArgumentError, 'Review verdicts must be booleans'
    end

    validate_evidence!(evidence_ids, reviewed_ids)
    return if row['needs_more_history']

    validate_explanation!(row, evidence_ids)
  end

  def validate_explanation!(row, evidence_ids)
    unless row.values_at('category', 'reason').all? { |value| value.is_a?(String) && value.present? }
      raise ArgumentError, 'Reviewed findings need a category and reason'
    end
    raise ArgumentError, 'Matched findings need supporting evidence' if row['matched'] && evidence_ids.empty?
  end

  def validate_evidence!(evidence_ids, reviewed_ids)
    return if evidence_ids.is_a?(Array) && evidence_ids.all?(Integer) && (evidence_ids - reviewed_ids).empty?

    raise ArgumentError, 'Evidence IDs must come from the reviewed messages'
  end

  def feature_name
    'copilot_review'
  end
end
