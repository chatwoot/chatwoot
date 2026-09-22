class ConversationMonitors::ContextBuilder
  def initialize(conversation)
    @conversation = conversation
  end

  def build
    state = { messages: [], customer_context: customer_context }
    bytes = state.to_json.bytesize
    each_message do |message|
      next if message.content_attributes['deleted']

      text = public_text(message)
      next unless text

      entry = { speaker: message.incoming? ? 'customer' : 'agent', text: ActionController::Base.helpers.strip_tags(text) }
      bytes += entry.to_json.bytesize
      raise CustomExceptions::MonitorEvaluationError, 'context_limit' if bytes > ConversationMonitors::Configuration::MAX_CONTEXT_BYTES

      state[:messages] << entry
    end
    raise CustomExceptions::MonitorEvaluationError, 'no_text' if state[:messages].empty?

    state
  end

  private

  def public_text(message)
    text = message.content_for_llm
    text if text.present? && text != '[Attachment]'
  end

  def each_message(&)
    scope = @conversation.messages.where(private: false, message_type: [:incoming, :outgoing]).includes(:attachments).reorder(:created_at, :id)
    loop do
      batch = scope.limit(50).to_a
      batch.each(&)
      break if batch.size < 50

      last = batch.last
      scope = scope.where('(created_at, id) > (?, ?)', last.created_at, last.id)
    end
  end

  def customer_context
    keys = ConversationMonitors::Configuration.attribute_keys
    {
      contact_attributes: @conversation.contact.custom_attributes.slice(*keys),
      conversation_attributes: @conversation.custom_attributes.slice(*keys)
    }
  end
end
