class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  include Events::Types

  before_action :ensure_api_inbox, only: :update

  def index
    @messages = message_finder.perform
  end

  def create
    user = Current.user || @resource
    mb = Messages::MessageBuilder.new(user, @conversation, params)
    @message = mb.perform

    trigger_typing_event(CONVERSATION_TYPING_OFF)
  rescue StandardError => e
    render_rescued_error(e)
  end

  def update
    Messages::StatusUpdateService.new(message, permitted_params[:status], permitted_params[:external_error]).perform
    @message = message
  end

  def destroy
    authorize message, :destroy?

    # Locking the row serializes this with an outgoing send still in flight, and the `source_id` is
    # read inside that critical section: either we get there first and the send revokes the message
    # when it persists the `source_id`, or the send got there first and we see the real `source_id`
    # here. Exactly one of the two sides enqueues the provider delete.
    reached_provider = false
    message.with_lock do
      # The reserved provider id survives the wipe: a send still in flight is what this delete races
      # with, and dropping the reservation would leave its echo unmatchable — the deleted content
      # would come back as a fresh incoming-looking message. The forward marker survives too, so
      # replies to a deleted forward stay out of this conversation.
      deleted_attributes = message.content_attributes.slice('forwarded_message_id')
                                  .merge(deleted: true, pending_source_id: message.pending_source_id).compact
      message.update!(content: I18n.t('conversations.messages.deleted'), content_type: :text, content_attributes: deleted_attributes)
      message.attachments.destroy_all
      reached_provider = message.source_id.present?
    end
    delete_message_on_channel if reached_provider
  end

  def retry
    return if message.blank?
    return head :unprocessable_entity unless claim_message_for_retry

    ::SendReplyJob.perform_later(message.id)
  rescue StandardError => e
    render_rescued_error(e)
  end

  # Asks the provider for the file of a history message that arrived without it. The
  # answer comes later, as an update of the message, or as the bubble saying the file is
  # no longer available.
  def fetch_media
    history_media = Whatsapp::Session::HistoryMedia
    return head :unprocessable_entity unless @conversation.inbox.channel.try(:session_provider?) && history_media.pending?(message)

    history_media.enqueue(message)
    head :accepted
  end

  def translate
    return head :ok if already_translated_content_available?

    translated_content = translate_message

    if translated_content.present?
      translations = {}
      translations[permitted_params[:target_language]] = translated_content
      translations = message.translations.merge!(translations) if message.translations.present?
      message.update!(translations: translations, translation_provider: translation_provider)
    end

    render json: { content: translated_content }
  rescue Google::Cloud::Error => e
    # `details` carries the clean human message; `message` includes gRPC debug noise
    render_could_not_create_error(e.details.presence || e.message)
  end

  def edit_content
    new_content = params[:content]
    return render json: { error: 'Content is required' }, status: :unprocessable_entity if new_content.blank?
    return render json: { error: 'Content exceeds maximum length' }, status: :unprocessable_entity if new_content.length > 150_000
    return render json: { error: 'Only outgoing messages can be edited' }, status: :forbidden unless message.outgoing?

    original_content = message.content
    # Only save previous_content on first edit to preserve the original message
    previous_content_to_save = message.is_edited ? message.previous_content : original_content
    # The write below is optimistic: the channel has not taken the edit yet, and the rescue in
    # `edit_message_on_channel` writes the body back when it refuses. An automation must not run on a
    # body the contact never received, so the row's own announcement is deferred and made here, once
    # the channel has accepted (fazer-ai/chatwoot#648).
    message.defer_edit_announcement = true
    message.update!(content: new_content, is_edited: true, previous_content: previous_content_to_save)

    edit_message_on_channel(new_content, original_content)
    message.announce_edit

    @message = message.reload
  end

  private

  def translation_provider
    'google_translate'
  end

  def translate_message
    hook = Current.account.hooks.find_by(app_id: 'google_translate')
    Integrations::GoogleTranslate::ProcessorService.new(hook: hook).translate_message(message, permitted_params[:target_language]) if hook
  end

  def message
    @message ||= @conversation.messages.find(permitted_params[:id])
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end

  # A retry clears the failure, not what the message is. A pending contact-info request keeps the marker
  # the eligibility check reads, and a bare retry would send the interactive message with no record of
  # what it is. An email keeps its recipients, its subject and the forward it carries: without them the
  # resend would go to the contact as a plain reply.
  RETRY_KEPT_CONTENT_ATTRIBUTES = %w[forwarded_message_id to_emails cc_emails bcc_emails email].freeze

  def retry_content_attributes
    return message.content_attributes if message.content_attributes.dig('whatsapp_contact_info', 'type') == 'request'

    message.content_attributes.slice(*RETRY_KEPT_CONTENT_ATTRIBUTES)
  end

  def permitted_params
    params.permit(:id, :target_language, :status, :external_error, :content)
  end

  def already_translated_content_available?
    message.translations.present? && message.translations[permitted_params[:target_language]].present?
  end

  def delete_message_on_channel
    return unless @conversation.inbox.channel.respond_to?(:delete_message)

    ::Messages::DeleteOnChannelJob.perform_later(message.id)
  end

  # One claim, not two. Both halves used to run in sequence and the first flipped the very status
  # the second tested, so the second could only ever answer false and the send job it guarded was
  # never queued: Retry cleared the failure marker and delivered nothing.
  #
  # The `deleted?` check and the `content_attributes` reset have to share the lock the DELETE endpoint
  # takes: a delete landing between them would have its flag wiped by the reset, and the job `retry`
  # queues afterwards would then push the "deleted" placeholder to the contact.
  def claim_message_for_retry
    message.with_lock do
      next false if message.deleted?
      next false unless message.failed? && (message.outgoing? || message.template?)

      Messages::StatusUpdateService.new(message, 'sent').perform
      reset_message_state_for_retry
      true
    end
  end

  # Called from inside the claim's lock, so the reset cannot land between a delete and its check.
  def reset_message_state_for_retry
    previous_source_id = message.source_id
    retry_attributes = { content_attributes: retry_content_attributes }
    # An API or web widget inbox owns its source_id: it is the caller's own reference, and the
    # reply job there is an email notification rather than a channel send. On a provider channel
    # a stale id instead makes Base::SendOnChannelService treat the message as already sent.
    retry_attributes[:source_id] = nil unless @conversation.inbox.api? || @conversation.inbox.web_widget?
    message.update!(retry_attributes)
    return unless retry_attributes.key?(:source_id) && previous_source_id.present?

    Rails.logger.info "Cleared older source ID #{previous_source_id} for message #{message.id}"
  end

  def edit_message_on_channel(new_content, original_content)
    return unless @conversation.inbox.channel.respond_to?(:edit_message)
    return if message.source_id.blank?

    @conversation.inbox.channel.edit_message(message, new_content, conversation: @conversation)
  rescue StandardError => e
    Rails.logger.error "Failed to edit message on channel: #{e.message}"
    was_already_edited = message.previous_content != original_content
    if was_already_edited
      message.update!(content: original_content)
    else
      message.update!(content: original_content, is_edited: false, previous_content: nil)
    end
    announce_restored_content
    raise e
  end

  # The body that came back is the one the contact has, and the rules for it may never have run: the
  # announcement that named it found this refused body on the row and stood down (#660, #661).
  # `Message#announce_restored_body` is what decides whether there is anything to say, and it has two
  # questions to answer rather than one -- a write-back that undid a first edit takes the edit marker with
  # it and announces no edit, and yet the body it put back may be one a recovery brought and nobody ever
  # asked the arrival rules about (#666).
  #
  # Swallowed on purpose. The channel's own error is the one the agent needs to see, and replacing it with
  # one about the job transport would cost them the reason their edit did not go out.
  def announce_restored_content
    message.announce_restored_body
  rescue StandardError => e
    Rails.logger.error "Failed to announce the restored content: #{e.message}"
  end

  # API inbox check
  def ensure_api_inbox
    # Only API inboxes can update messages
    render json: { error: 'Message status update is only allowed for API inboxes' }, status: :forbidden unless @conversation.inbox.api?
  end

  def trigger_typing_event(event)
    user = Current.user || @resource
    return unless user.is_a?(User)

    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: @conversation, user: user, is_private: params[:private])
  end
end

Api::V1::Accounts::Conversations::MessagesController.prepend_mod_with('Api::V1::Accounts::Conversations::MessagesController')
