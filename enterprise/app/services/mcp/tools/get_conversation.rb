class Mcp::Tools::GetConversation < Mcp::Tools::Base
  MESSAGE_LIMIT = 50

  tool_name 'get_conversation'
  description "Read one conversation and its latest #{MESSAGE_LIMIT} messages, oldest first. " \
              'A message with private true is an internal note that the customer cannot see.'
  scope 'conversations:read'
  annotations(read_only_hint: true, destructive_hint: false, open_world_hint: false)
  input_schema(
    properties: {
      conversation_id: { type: 'integer', description: 'The conversation id from list_conversations.' }
    },
    required: ['conversation_id']
  )

  def self.perform(conversation_id:)
    conversation = find_conversation(conversation_id)
    messages = conversation.messages.non_activity_messages.includes(:sender).limit(MESSAGE_LIMIT).reverse

    respond(conversation_summary(conversation).merge(messages: messages.map { |message| message_summary(message) }))
  end

  def self.message_summary(message)
    {
      id: message.id,
      type: message.message_type,
      private: message.private,
      sender: message.sender&.name,
      content: message.content,
      attachments: message.attachments.size,
      created_at: message.created_at.iso8601
    }
  end
  private_class_method :message_summary
end
