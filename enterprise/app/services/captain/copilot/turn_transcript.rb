class Captain::Copilot::TurnTranscript
  def initialize(run, chat, protocol:)
    @run = run
    @chat = chat
    @protocol = protocol
    @replayed_run_ids = []
    @identity = { 'model' => chat.model.id, 'provider' => chat.provider.slug, 'protocol' => protocol.to_s,
                  'endpoint' => InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value }
  end

  def load
    history = @run.copilot_thread.copilot_messages.where(message_type: %w[user assistant])
                  .where(CopilotMessage.arel_table[:id].lteq(@run.copilot_message_id)).includes(:copilot_run).order(:id)
    history.each { |message| add_history(message) }
    @offset = @chat.messages.size
    state = @run.transcript
    return if state.empty?

    raise ArgumentError, 'The model or provider changed during this run' unless state['identity'] == @identity

    state.fetch('messages', []).each { |attributes| @chat.add_message(attributes.symbolize_keys) }
  end

  def save(token)
    messages = @chat.messages[@offset..].map { |message| serialized_message(message) }
    @run.with_lease(token) { @run.update!(transcript: { identity: @identity, messages: messages }) }
  end

  private

  def add_history(message)
    return if message.assistant? && @replayed_run_ids.include?(message.message['run_id'])

    @chat.add_message(role: message.message_type.to_sym, content: message.message['content'].to_s)
    prior = message.copilot_run
    return unless prior && prior.id != @run.id

    append_earlier_turn(prior)
  end

  def append_earlier_turn(prior)
    if prior.transcript['identity'] == @identity && prior.completed?
      prior.transcript.fetch('messages', []).each { |attributes| @chat.add_message(attributes.symbolize_keys) }
      @replayed_run_ids << prior.id
    else
      outcomes = prior.tool_calls.order(:id).map(&:summary)
      @chat.add_message(role: :assistant, content: { run: prior.summary, tool_calls: outcomes }.to_json) if outcomes.any?
    end
  end

  def serialized_message(message)
    attributes = message.to_h.except(:cost, :attachments)
    body = message.raw.respond_to?(:body) ? message.raw.body : message.raw
    if @protocol == :responses && message.role == :assistant && body.is_a?(Hash) && body['output'].is_a?(Array)
      attributes[:raw_content] = body['output']
      # Keep every Responses item, including reasoning and commentary phases, during this loop as well as later turns.
      index = @chat.messages.index(message)
      @chat.messages[index] = RubyLLM::Message.new(attributes)
    end
    attributes
  end
end
