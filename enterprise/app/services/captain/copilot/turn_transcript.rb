class Captain::Copilot::TurnTranscript
  # Earlier turns replayed whole, with their tool results and reasoning. Older ones keep what their tool calls did and the
  # saved sets they made, so a thread kept open all day does not resend everything on every model call.
  REPLAYED_TURNS = 3

  def initialize(run, chat, protocol:)
    @run = run
    @chat = chat
    @protocol = protocol
    @replayed_run_ids = []
    @identity = { 'model' => chat.model.id, 'provider' => chat.provider.slug, 'protocol' => protocol.to_s,
                  'endpoint' => InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value }
  end

  def load
    history = thread_history
    @whole_turn_ids = history.filter_map(&:copilot_run).map(&:id).excluding(@run.id).last(REPLAYED_TURNS)
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

  # The thread's messages up to and including this turn's, oldest first.
  def thread_history
    @run.copilot_thread.copilot_messages.where(message_type: %w[user assistant])
        .where(CopilotMessage.arel_table[:id].lteq(@run.copilot_message_id)).includes(:copilot_run).order(:id).to_a
  end

  def add_history(message)
    return if message.assistant? && @replayed_run_ids.include?(message.message['run_id'])

    @chat.add_message(role: message.message_type.to_sym, content: message.message['content'].to_s)
    prior = message.copilot_run
    return unless prior && prior.id != @run.id

    append_earlier_turn(prior)
  end

  def append_earlier_turn(prior)
    if @whole_turn_ids.include?(prior.id) && prior.transcript['identity'] == @identity && prior.completed?
      prior.transcript.fetch('messages', []).each { |attributes| @chat.add_message(attributes.symbolize_keys) }
      @replayed_run_ids << prior.id
    else
      steps = prior.tool_calls.includes(:background_run).order(:id).map { |tool_call| outline(tool_call) }
      @chat.add_message(role: :assistant, content: { tool_calls: steps }.to_json) if steps.any?
    end
  end

  # What a tool call did and the saved set it made, without its result. display can show a saved set again.
  def outline(tool_call)
    { name: tool_call.name, arguments: tool_call.arguments, status: tool_call.status, error: tool_call.error,
      saved_set: tool_call.background_run&.summary }.compact
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
