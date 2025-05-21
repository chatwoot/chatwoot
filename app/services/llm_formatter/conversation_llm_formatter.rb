class LlmFormatter::ConversationLlmFormatter < LlmFormatter::DefaultLlmFormatter
  def format(config = {})
    sections = []
    sections << "Conversation ID: ##{@record.display_id}"
    sections << "Channel: #{@record.inbox.channel.name}"
    sections << 'Message History:'
    sections << if @record.messages.any?
                  build_messages
                else
                  'No messages in this conversation'
                end

    sections << "Contact Details: #{@record.contact.to_llm_text}" if config[:include_contact_details]
    sections.join("\n")
  end

  private

  def build_messages
    return "No messages in this conversation\n" if @record.messages.empty?

    message_text = ''
    @record.messages.chat.order(created_at: :asc).each do |message|
      message_text << format_message(message)
    end
    message_text
  end

  def format_message(message)
    sender = message.message_type == 'incoming' ? 'User' : 'Support agent'
    "#{sender}: #{message.content}\n"
  end
end
