class Mcp::Tools::SendMessage < Mcp::Tools::Base
  tool_name 'send_message'
  description 'Send a message in a conversation as the user. By default the message is a reply that the customer receives and it cannot be ' \
              'recalled. Set private to true to add an internal note that only teammates see.'
  scope 'messages:write'
  annotations(read_only_hint: false, destructive_hint: false, open_world_hint: true)
  input_schema(
    properties: {
      conversation_id: { type: 'integer', description: 'The conversation id from list_conversations.' },
      content: { type: 'string', minLength: 1, description: 'The message text. Markdown is supported.' },
      private: { type: 'boolean', description: 'true adds an internal note. Defaults to false, which replies to the customer.' }
    },
    required: %w[conversation_id content]
  )

  def self.perform(conversation_id:, content:, private: false)
    conversation = find_conversation(conversation_id)
    message = Messages::MessageBuilder.new(Current.user, conversation, { content: content, private: private }).perform

    respond(id: message.id, conversation_id: conversation.display_id, private: message.private, created_at: message.created_at.iso8601)
  end
end
