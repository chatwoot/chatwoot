class Captain::Conversation::ResponseBuilderJob < ApplicationJob
  include Captain::ChatHelper

  MAX_MESSAGE_LENGTH = 10_000
  retry_on ActiveStorage::FileNotFoundError, attempts: 3

  def perform(conversation, assistant)
    @conversation = conversation
    @inbox = conversation.inbox
    @assistant = assistant

    Current.executed_by = @assistant

    ActiveRecord::Base.transaction do
      generate_and_process_response
    end
  rescue StandardError => e
    raise e if e.is_a?(ActiveStorage::FileNotFoundError)

    handle_error(e)
  ensure
    Current.executed_by = nil
  end

  private

  delegate :account, :inbox, to: :@conversation

  def generate_and_process_response
    @response = Captain::Llm::AssistantChatService.new(assistant: @assistant).generate_response(
      message_history: collect_previous_messages
    )

    return process_action('handoff') if handoff_requested?

    create_messages
    Rails.logger.info("[CAPTAIN][ResponseBuilderJob] Incrementing response usage for #{account.id}")
    account.increment_response_usage
  end

  def collect_previous_messages(include_all: false)
    messages_query = @conversation
                     .messages
                     .where(message_type: [:incoming, :outgoing])

    messages_query = messages_query.where(private: false) unless include_all

    messages_query.map do |message|
      {
        content: message_content_multimodal(message),
        role: determine_role(message)
      }
    end
  end

  def determine_role(message)
    return 'system' if message.content.blank?

    message.message_type == 'incoming' ? 'user' : 'system'
  end

  def message_content_multimodal(message)
    parts = []

    parts << text_part(message.content) if message.content.present?
    parts.concat(attachment_parts(message.attachments)) if message.attachments.any?

    finalize_content_parts(parts)
  end

  def text_part(text)
    { type: 'text', text: text }
  end

  def attachment_parts(attachments)
    [].tap do |parts|
      parts.concat(image_parts(attachments.where(file_type: :image)))

      transcription = extract_audio_transcriptions(attachments)
      parts << text_part(transcription) if transcription.present?

      parts << text_part('User has shared an attachment') if attachments.where.not(file_type: %i[image audio]).exists?
    end
  end

  def image_parts(image_attachments)
    image_attachments.each_with_object([]) do |attachment, parts|
      url = get_attachment_url(attachment)
      next if url.blank?

      parts << {
        type: 'image_url',
        image_url: { url: url }
      }
    end
  end

  def finalize_content_parts(parts)
    return 'Message without content' if parts.blank?
    return parts.first[:text] if single_text_part?(parts)

    parts
  end

  def single_text_part?(parts)
    parts.one? && parts.first[:type] == 'text'
  end

  def get_attachment_url(attachment)
    return attachment.external_url if attachment.external_url.present?

    return unless attachment.file.attached?

    begin
      attachment.file_url
    rescue ActiveStorage::FileNotFoundError
      nil
    end
  end

  def handoff_requested?
    @response['response'] == 'conversation_handoff'
  end

  def process_action(action)
    case action
    when 'handoff'
      I18n.with_locale(@assistant.account.locale) do
        create_handoff_message
        @conversation.bot_handoff!
      end
    end
  end

  def create_handoff_message
    create_outgoing_message(@assistant.config['handoff_message'].presence || I18n.t('conversations.captain.handoff'))
  end

  def create_messages
    validate_message_content!(@response['response'])
    create_outgoing_message(@response['response'])
  end

  def validate_message_content!(content)
    raise ArgumentError, 'Message content cannot be blank' if content.blank?
  end

  def create_outgoing_message(message_content)
    @conversation.messages.create!(
      message_type: :outgoing,
      account_id: account.id,
      inbox_id: inbox.id,
      sender: @assistant,
      content: message_content
    )
  end

  def handle_error(error)
    log_error(error)
    process_action('handoff')
    true
  end

  def log_error(error)
    ChatwootExceptionTracker.new(error, account: account).capture_exception
  end
end
