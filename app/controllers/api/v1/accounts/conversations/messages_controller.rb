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
    extra_attrs = build_message_update_attrs

    if permitted_params[:status].present?
      # Pre-stage source_id / content_attributes onto the in-memory record so
      # the service's save! flushes them in the same UPDATE statement. This
      # collapses what would otherwise be two writes (and two
      # after_update_commit dispatches) into one.
      message.assign_attributes(extra_attrs) if extra_attrs.any?
      status_applied = Messages::StatusUpdateService.new(
        message, permitted_params[:status], permitted_params[:external_error]
      ).perform
      # If the status transition was rejected by the service, still persist
      # the source_id / content_attributes the caller supplied -- they are an
      # independent backfill and shouldn't depend on the status path.
      message.save! if !status_applied && message.changed?
    elsif extra_attrs.any?
      message.update!(extra_attrs)
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
    params.permit(:id, :target_language, :status, :external_error, :source_id, content_attributes: {})
  end

  # Build the attributes hash for the API-channel "extra" update path -- the
  # platform-side message id (source_id) and free-form content_attributes
  # that custom bridges (e.g. LINE / WhatsApp) backfill after relaying an
  # outgoing agent message to the downstream channel.
  #
  # Behaviour:
  # - `source_id` is only written when a non-nil value is supplied, so a
  #   status-only PATCH that happens to serialize `"source_id": null` cannot
  #   accidentally clear an already-stored id. Callers that genuinely need
  #   to clear the field can do so via a direct DB update or an explicit
  #   clear endpoint.
  # - `content_attributes` is **deep-merged** with the existing JSON so
  #   partial updates to nested objects (e.g. one subkey under `email`) do
  #   not blow away unrelated siblings. Keys are normalised to strings on
  #   both sides to stay consistent with how Rails's JSON store reads back
  #   from the JSONB column.
  def build_message_update_attrs
    attrs = {}
    attrs[:source_id] = permitted_params[:source_id] unless permitted_params[:source_id].nil?

    if permitted_params[:content_attributes].present?
      incoming = permitted_params[:content_attributes].to_h.deep_stringify_keys
      existing = (message.content_attributes || {}).deep_stringify_keys
      attrs[:content_attributes] = existing.deep_merge(incoming)
    end

    attrs
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
