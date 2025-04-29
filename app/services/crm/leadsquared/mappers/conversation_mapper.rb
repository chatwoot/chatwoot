class Crm::Leadsquared::Mappers::ConversationMapper
  include ::Rails.application.routes.url_helpers

  # https://help.leadsquared.com/what-is-the-maximum-character-length-supported-for-lead-and-activity-fields/
  # the rest of the body of the note is around 200 chars
  # so this limits it
  ACTIVITY_NOTE_MAX_SIZE = 1800

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
    I18n.t('crm.created_activity',
           brand_name: brand_name,
           channel_info: conversation.inbox.name,
           formatted_creation_time: formatted_creation_time,
           display_id: conversation.display_id,
           url: conversation_url)
  end

  def transcript_activity
    return I18n.t('crm.no_message') if transcript_messages.empty?

    I18n.t('crm.transcript_activity',
           brand_name: brand_name,
           channel_info: conversation.inbox.name,
           display_id: conversation.display_id,
           url: conversation_url,
           format_messages: format_messages)
  end

  private

  attr_reader :conversation, :messages

  def formatted_creation_time
    conversation.created_at.strftime('%Y-%m-%d %H:%M:%S')
  end

  def transcript_messages
    @transcript_messages ||= messages || conversation.messages.chat.select(&:conversation_transcriptable?)
  end

  def format_messages
    selected_messages = []
    separator = "\n\n"
    current_length = 0

    # Reverse the messages to have latest on top
    transcript_messages.reverse_each do |message|
      formatted_message = format_message(message)
      required_length = formatted_message.length + separator.length # the last one does not need to account for separator, but we add it anyway

      break unless (current_length + required_length) <= ACTIVITY_NOTE_MAX_SIZE

      selected_messages << formatted_message
      current_length += required_length
    end

    selected_messages.join(separator)
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
    message.content.presence || I18n.t('crm.no_content')
  end

  def attachment_info(message)
    return '' unless message.attachments.any?

    attachments = message.attachments.map { |a| I18n.t('crm.attachment', type: a.file_type) }.join(', ')
    "\n#{attachments}"
  end

  def conversation_url
    app_account_conversation_url(account_id: conversation.account.id, id: conversation.display_id)
  end

  def brand_name
    ::GlobalConfig.get('BRAND_NAME')['BRAND_NAME'] || 'Chatwoot'
  end
end
