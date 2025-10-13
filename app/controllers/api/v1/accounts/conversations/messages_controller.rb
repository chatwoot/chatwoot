class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  # before_action :ensure_api_inbox, only: :update

  def index
    @messages = message_finder.perform
  end

  def create
    user = Current.user || @resource
    mb = Messages::MessageBuilder.new(user, @conversation, params)
    @message = mb.perform
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def update
    # Track who performed the update so listeners can use it
    with_execution_context do
      handle_status_update
      handle_content_update
      @message = message
    end
  rescue StandardError => e
    render_could_not_create_error(e.message)
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

  private

  def message
    @message ||= @conversation.messages.find(permitted_params[:id])
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end

  def permitted_params
    params.permit(:id, :target_language)
  end

  def permitted_status_params
    params.permit(:status, :external_error)
  end

  def permitted_content_params
    # Allow updating content and content_attributes
    params.permit(:content, content_attributes: {})
  end

  def already_translated_content_available?
    message.translations.present? && message.translations[permitted_params[:target_language]].present?
  end

  # API inbox check
  def ensure_api_inbox!
    # Only API inboxes can update message status
    if @conversation.inbox.api?
      true
    else
      render json: { error: 'Message status update is only allowed for API inboxes' }, status: :forbidden
      false
    end
  end

  # Extracted helpers to reduce complexity of update
  def with_execution_context
    Current.executed_by = Current.user || @resource
    yield
  ensure
    # Reset executed_by to avoid leaking context
    Current.executed_by = nil
  end

  def handle_status_update
    status = permitted_status_params[:status]
    return if status.blank?

    return unless ensure_api_inbox!

    Messages::StatusUpdateService.new(
      message,
      status,
      permitted_status_params[:external_error]
    ).perform
  end

  def handle_content_update
    attrs = permitted_content_params
    return if attrs.blank?

    if attrs.key?(:content_attributes)
      merged_attrs = (message.content_attributes || {}).deep_merge(attrs[:content_attributes].to_h)
      attrs = attrs.merge(content_attributes: merged_attrs)
    end

    message.update!(attrs)
  end
end
