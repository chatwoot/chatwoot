class LlmFormatter::ConversationLlmFormatter < LlmFormatter::DefaultLlmFormatter
  def format(config = {})
    sections = []
    sections << "Conversation ID: ##{@record.display_id}"
    sections << "Channel: #{@record.inbox.channel.name}"
    sections << 'Message History:'
    sections << if @record.messages.any?
                  build_messages(config)
                else
                  'No messages in this conversation'
                end

    sections << "Contact Details: #{@record.contact.to_llm_text}" if config[:include_contact_details]

    attributes = build_attributes
    if attributes.present?
      sections << 'Conversation Attributes:'
      sections << attributes
    end

    sections.join("\n")
  end

  private

  def build_messages(config = {})
    return "No messages in this conversation\n" if @record.messages.empty?

    message_text = ''
    messages = @record.messages.where.not(message_type: :activity).order(created_at: :asc)

    messages.each do |message|
      # Skip private messages unless explicitly included in config
      next if message.private? && !config[:include_private_messages]

      message_text << format_message(message)
    end
    message_text
  end

  def format_message(message)
    sender = case message.sender_type
             when 'User'
               'Support Agent'
             when 'Contact'
               'User'
             else
               'Bot'
             end
    sender = "[Private Note] #{sender}" if message.private?
    "#{sender}: #{message.content_for_llm}\n"
  end

  def build_attributes
    attributes = @record.account.custom_attribute_definitions.with_attribute_model('conversation_attribute').map do |attribute|
      "#{attribute.attribute_display_name}: #{@record.custom_attributes[attribute.attribute_key]}"
    end
    attributes.join("\n")
  end
end
