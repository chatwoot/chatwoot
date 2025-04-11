class Crm::Leadsquared::Mappers::ConversationMapper
  include ::Rails.application.routes.url_helpers

  def self.map_conversation_activity(conversation)
    new(conversation).conversation_activity
  end

  def self.map_transcript_activity(conversation, messages = nil)
    new(conversation, messages).transcript_activity
  end

  def initialize(conversation, messages = nil)
    @conversation = conversation
    @messages = messages
  end

  def conversation_activity
    <<~NOTE.strip
      New conversation started on #{brand_name}

      Channel: #{channel_info}
      Created: #{formatted_creation_time}
      Conversation ID: #{conversation.display_id}
      #{conversation_url}
    NOTE
  end

  def transcript_activity
    return 'No messages in conversation' if transcript_messages.empty?

    <<~TRANSCRIPT.strip
      Conversation Transcript from #{brand_name}

      Channel: #{channel_info}
      Conversation ID: #{conversation.display_id}
      #{conversation_url}

      Transcript:
      #{format_messages}
    TRANSCRIPT
  end

  private

  attr_reader :conversation, :messages

  def channel_info
    "#{conversation.inbox.channel_type} (#{conversation.inbox.name})"
  end

  def formatted_creation_time
    conversation.created_at.strftime('%Y-%m-%d %H:%M:%S')
  end

  def transcript_messages
    @transcript_messages ||= messages || conversation.messages.chat.select(&:conversation_transcriptable?)
  end

  def format_messages
    transcript_messages.map do |message|
      format_message(message)
    end.join("\n\n")
  end

  def format_message(message)
    <<~MESSAGE.strip
      [#{message_time(message)}] #{sender_name(message)}: #{message_content(message)}#{attachment_info(message)}
    MESSAGE
  end

  def message_time(message)
    # TODO: Figure out what timezone to send the time in
    message.created_at.strftime('%Y-%m-%d %H:%M')
  end

  def sender_name(message)
    return 'System' if message.sender.nil?

    message.sender.name.presence || "#{message.sender_type} #{message.sender_id}"
  end

  def message_content(message)
    message.content.presence || '[No content]'
  end

  def attachment_info(message)
    return '' unless message.attachments.any?

    attachments = message.attachments.map { |a| "[Attachment: #{a.file_type}]" }.join(', ')
    "\n#{attachments}"
  end

  def conversation_url
    url = app_account_conversation_url(account_id: conversation.account.id, id: conversation.display_id)
    "View in #{brand_name}: #{url}"
  end

  def brand_name
    ::GlobalConfig.get('BRAND_NAME')['BRAND_NAME'] || 'Chatwoot'
  end
end
