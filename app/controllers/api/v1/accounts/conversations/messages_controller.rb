class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_api_inbox, only: :update

  def index
    @messages = message_finder.perform
  end

  def create
    user = Current.user || @resource
    @message = Messages::MessageBuilder.new(user, @conversation, params).perform
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def update
    Messages::StatusUpdateService.new(message, permitted_params[:status], permitted_params[:external_error]).perform
    @message = message
  end

  def destroy
    ActiveRecord::Base.transaction do
      message.update!(content: I18n.t('conversations.messages.deleted'), content_type: :text, content_attributes: { deleted: true })
      message.attachments.destroy_all
    end
  end

  def retry
    return if message.blank?

    service = Messages::StatusUpdateService.new(message, 'sent')
    service.perform
    message.update!(content_attributes: {})
    ::SendReplyJob.perform_later(message.id)
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def translate
    return head :ok if already_translated_content_available?

    translated_content = Integrations::GoogleTranslate::ProcessorService.new(
      message: message,
      target_language: permitted_params[:target_language]
    ).perform

    if translated_content.present?
      translations = {}
      translations[permitted_params[:target_language]] = translated_content
      translations = message.translations.merge!(translations) if message.translations.present?
      message.update!(translations: translations)
    end

    render json: { content: translated_content }
  end

  def retry_transcription
    return render json: { error: 'Message not found' }, status: :not_found if message.blank?

    audio_attachments = message.attachments.where(file_type: :audio)
    return render json: { error: 'No audio attachments found' }, status: :unprocessable_entity if audio_attachments.empty?

    # Clear existing transcription metadata
    attrs = message.content_attributes || {}
    attrs.delete('transcription')
    message.update!(content_attributes: attrs)

    # Re-enqueue transcription jobs for all audio attachments
    audio_attachments.each do |attachment|
      Rails.logger.info "Re-enqueueing transcription for message #{message.id}, attachment #{attachment.id}"
      TranscribeAudioMessageJob.perform_later(message.id, attachment.id)
    end

    render json: { message: 'Transcription retry initiated' }, status: :ok
  rescue StandardError => e
    Rails.logger.error "Error retrying transcription: #{e.message}"
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def message
    @message ||= @conversation.messages.find(permitted_params[:id])
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end

  def permitted_params
    params.permit(:id, :target_language, :status, :external_error)
  end

  def already_translated_content_available?
    message.translations.present? && message.translations[permitted_params[:target_language]].present?
  end

  # API inbox check
  def ensure_api_inbox
    # Only API inboxes can update messages
    render json: { error: 'Message status update is only allowed for API inboxes' }, status: :forbidden unless @conversation.inbox.api?
  end
end
