class ConversationMonitors::ContextBuilder
  def initialize(conversation, message_limit: nil)
    @conversation = conversation
    @message_limit = message_limit
    @truncated = false
  end

  def build
    state = { messages: [], customer_context: customer_context, truncated: @truncated }
    each_message do |message|
      text = public_text(message)
      next unless text

      if @message_limit && state[:messages].size >= @message_limit
        state[:truncated] = true
        break
      end

      entry = { speaker: message.incoming? ? 'customer' : 'agent', text: text }
      state[:messages].unshift(entry)
      next if state.to_json.bytesize <= ConversationMonitors::Configuration::MAX_CONTEXT_BYTES

      state[:truncated] = true
      trim_oldest_message(state)
      break
    end
    raise CustomExceptions::MonitorEvaluationError, 'no_text' if state[:messages].empty?

    state
  end

  private

  def public_text(message)
    return if message.content_attributes['deleted']

    text = message.content_for_llm
    return if text.blank? || text == '[Attachment]'

    # HTML conversion preserves block boundaries; plain messages keep their own whitespace.
    text.match?(%r{</?[a-z][^>]*>}i) ? Html2Text.convert(text).presence : text.presence
  end

  def trim_oldest_message(state)
    entry = state[:messages].first
    text = entry[:text]
    # Search character boundaries using the encoded size, including JSON escapes.
    first_over_limit = (0..text.length).bsearch do |length|
      entry[:text] = text.last(length)
      state.to_json.bytesize > ConversationMonitors::Configuration::MAX_CONTEXT_BYTES
    end
    retained_length = [(first_over_limit || text.length) - 1, 0].max
    entry[:text] = text.last(retained_length)
    state[:messages].shift if entry[:text].blank?
  end

  def each_message(&)
    scope = @conversation.messages.where(private: false, message_type: [:incoming, :outgoing])
                         .includes(:attachments).reorder(created_at: :desc, id: :desc)
    batch_size = @message_limit ? @message_limit + 1 : 50
    loop do
      batch = scope.limit(batch_size).to_a
      batch.each(&)
      break if batch.size < batch_size

      last = batch.last
      scope = scope.where('(created_at, id) < (?, ?)', last.created_at, last.id)
    end
  end

  def customer_context
    keys = ConversationMonitors::Configuration.attribute_keys
    attributes = {
      contact_attributes: @conversation.contact.custom_attributes.slice(*keys),
      conversation_attributes: @conversation.custom_attributes.slice(*keys)
    }
    context = { contact_attributes: {}, conversation_attributes: {} }
    attributes.each do |source, values|
      values.each do |key, value|
        context[source][key] = value
        next if context.to_json.bytesize <= ConversationMonitors::Configuration::MAX_CUSTOMER_CONTEXT_BYTES

        context[source].delete(key)
        @truncated = true
      end
    end
    context
  end
end
