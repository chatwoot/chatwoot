class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_api_inbox, only: :update

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
    attrs = {}
    # `source_id` is only written when a non-nil value is supplied so a
    # status-only PATCH that happens to serialize `"source_id": null` cannot
    # accidentally clear an already-stored id.
    attrs[:source_id] = permitted_params[:source_id] unless permitted_params[:source_id].nil?

    # `content_attributes` is deep-merged with the existing JSON so partial
    # updates to nested objects (e.g. one subkey under `email`) do not blow
    # away unrelated siblings. Keys are normalised to strings on both sides
    # to stay consistent with how Rails reads back from the JSONB column.
    if permitted_params[:content_attributes].present?
      incoming = permitted_params[:content_attributes].to_h.deep_stringify_keys
      attrs[:content_attributes] = (message.content_attributes || {}).deep_stringify_keys.deep_merge(incoming)
    end

    # When `status` is supplied alongside the new fields, pre-stage the
    # extra attrs so StatusUpdateService's save! flushes everything in one
    # UPDATE -- collapses what would be two writes (and two
    # after_update_commit dispatches) into one.
    if permitted_params[:status].present?
      message.assign_attributes(attrs) if attrs.any?
      Messages::StatusUpdateService.new(
        message, permitted_params[:status], permitted_params[:external_error]
      ).perform
    elsif attrs.any?
      message.update!(attrs)
    end

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

    ::SendReplyJob.perform_later(message.id) if claim_message_retry
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
  rescue Google::Cloud::Error => e
    # `details` carries the clean human message; `message` includes gRPC debug noise
    render_could_not_create_error(e.details.presence || e.message)
  end

  private

  def message
    @message ||= @conversation.messages.find(permitted_params[:id])
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end

  def claim_message_retry
    message.with_lock do
      next false unless message.failed?

      Messages::StatusUpdateService.new(message, 'sent').perform
      previous_source_id = message.source_id
      retry_attributes = { content_attributes: {} }
      retry_attributes[:source_id] = nil unless @conversation.inbox.api? || @conversation.inbox.web_widget?
      message.update!(retry_attributes)
      if retry_attributes.key?(:source_id) && previous_source_id.present?
        Rails.logger.info "Cleared older source ID #{previous_source_id} for message #{message.id}"
      end
      true
    end
  end

  def permitted_params
    params.permit(:id, :target_language, :status, :external_error, :source_id, content_attributes: {})
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
