# Mostly modeled after the intial implementation of the service based on 360 Dialog
# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/
class Whatsapp::IncomingMessageBaseService # rubocop:disable Metrics/ClassLength
  include ::Whatsapp::IncomingMessageServiceHelpers
  include ::Whatsapp::IncomingMessageIdentifierHelper
  include ::Whatsapp::IncomingContactMessageHandler

  pattr_initialize [:inbox!, :params!, :outgoing_echo, { locked_sender_id: nil }]

  def perform
    processed_params

    return process_statuses if processed_params.try(:[], :statuses).present?

    process_identity_change_messages
    return process_edited_message if edited_message?
    return process_revoked_message if revoked_message?
    return process_messages if messages_data.present?
  end

  # Returns messages array for both regular messages and echo events
  def messages_data
    return @messages_data if defined?(@messages_data)

    @processed_params&.dig(:messages) || @processed_params&.dig(:message_echoes)
  end

  private

  def process_messages # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/AbcSize,Metrics/MethodLength
    @lock_acquired = false

    # We don't support ephemeral message now, we need to skip processing the message
    # if the webhook event is an ephermal message or an unsupported message.
    # Reactions removed by the user arrive with an empty emoji and are skipped to match Baileys behavior.
    return if skip_message?

    # Multiple webhook event can be received against the same message due to misconfigurations in the Meta
    # business manager account. While we have not found the core reason yet, the following line ensure that
    # there are no duplicate messages created.
    return if find_message_by_source_id(messages_data.first[:id])

    @lock_acquired = acquire_message_processing_lock
    return unless @lock_acquired

    # Lock by contact phone to prevent race conditions when multiple messages
    # from the same contact arrive simultaneously (e.g., WhatsApp albums).
    with_contact_lock(contact_phone_for_lock) do
      # Re-check after acquiring lock to handle race conditions where an outgoing message
      # was sent from Chatwoot and the webhook arrived before source_id was saved
      next if find_message_by_source_id(messages_data.first[:id])

      # Reaction removals don't persist anything new, so peek for an existing
      # reaction row before set_contact: a removal webhook for a sender we
      # never stored has nothing to mark and shouldn't auto-create a contact
      # just to no-op. The match is sender-agnostic on purpose; the precise
      # filter happens inside `mark_existing_reaction_as_removed`.
      process_in_reply_to(messages_data.first)
      @referral = normalize_cloud_referral(messages_data.first)
      next if reaction_removal? && !existing_reaction_row?

      set_contact
      next if @contact.blank?

      # Reactions don't create a new Message row, so handle them outside the
      # transaction to avoid set_conversation opening/creating a stray thread
      # for a blank webhook. We also intentionally run this BEFORE
      # contact_processable? so blocked contacts can still reconcile an
      # existing reaction row.
      next mark_existing_reaction_as_removed if reaction_removal?

      next unless contact_processable?

      ActiveRecord::Base.transaction do
        set_conversation
        create_messages
      end
    end
  ensure
    # Clear lock AFTER transaction commits to prevent race conditions where another request
    # acquires the lock before this transaction is visible to other connections
    clear_message_source_id_from_redis if @lock_acquired
  end

  def skip_message?
    # Don't drop a Click-to-WhatsApp ad-click webhook even when its type would
    # otherwise be unprocessable (e.g. request_welcome): the ad referral is the
    # whole point of the message and must be persisted.
    return false if normalize_cloud_referral(messages_data.first).present?

    unprocessable_message_type?(message_type)
  end

  # For regular messages the contact phone is in :from; for echoes it's in :to.
  def contact_phone_for_lock
    outgoing_echo ? messages_data.first[:to] : messages_data.first[:from]
  end

  # Blocked contacts should not generate new incoming messages, but we still
  # accept echoes so outgoing messages tracked from native apps are preserved.
  def contact_processable?
    @contact.present? && !Whatsapp::BlockedSender.silenced?(@contact, from_me: outgoing_echo.present?)
  end

  def process_statuses
    status = @processed_params[:statuses].first
    return unless find_message_by_source_id(status[:id])

    update_whatsapp_identifiers_from_status(status)
    update_message_with_status(@message, status)
  rescue ArgumentError => e
    Rails.logger.error "Error while processing whatsapp status update #{e.message}"
  end

  def update_message_with_status(message, status)
    external_error = if status[:status] == 'failed' && status[:errors].present?
                       error = status[:errors]&.first
                       "#{error[:code]}: #{error[:title]}"
                     end

    Messages::StatusUpdateService.new(message, status[:status], external_error).perform
  end

  # WhatsApp Cloud delivers an in-place edit as a `type: "edit"` entry under the
  # `messages` field: the new content is nested in `edit.message` and the edited
  # message is referenced by `edit.original_message_id`. We update the stored
  # message in place to mirror the Baileys edit flow (is_edited + previous_content),
  # which the frontend already renders. Coexistence (embedded signup) inbound edits
  # arrive through this same `messages` path, so no echo-specific handling is needed.
  def edited_message?
    messages_data.present? && message_type == 'edit'
  end

  def revoked_message?
    messages_data.present? && message_type == 'revoke'
  end

  def process_edited_message
    edit = messages_data.first[:edit]
    return if edit.blank?
    return unless find_message_by_source_id(edit[:original_message_id])

    content = edited_message_content(edit[:message])
    return if content.blank?

    # Keep the earliest known content as previous_content across repeated edits.
    previous_content = @message.is_edited ? @message.previous_content : @message.content
    @message.update!(content: content, is_edited: true, previous_content: previous_content)
  end

  # WhatsApp Cloud delivers a sender-initiated delete as a `type: "revoke"` entry
  # under the `messages` field, referencing the deleted message via
  # `revoke.original_message_id`. We keep the original content and only flag the
  # message as deleted by the contact (the frontend marks it but still shows the text).
  def process_revoked_message
    revoke = messages_data.first[:revoke]
    return if revoke.blank?
    return unless find_message_by_source_id(revoke[:original_message_id])

    @message.update!(deleted_by_contact: true)
  end

  def create_messages
    message = messages_data.first
    return create_unsupported_message(message) if message_type == 'unsupported'

    log_error(message) && return if error_webhook_event?(message)

    message_type == 'contacts' ? create_contact_messages(message) : create_regular_message(message)
  end

  # Cloud delivers a reaction removal as a webhook with empty emoji. Our schema
  # keeps a single Message row per (target, sender) with `deleted` toggled on it,
  # so we update that row in place.
  #
  # Two paths converge here:
  # - Incoming: contact removed their reaction; mark the contact-owned row.
  # - Outgoing echo (multi-device, agent un-reacted from the connected phone):
  #   mark the senderless outgoing row. The Chatwoot-originated removal echo
  #   also lands here, but the active-only filter drops it (the controller
  #   already toggled the row to deleted) so it no-ops harmlessly.
  #
  # Lookup is intentionally NOT scoped to `@conversation`: the reaction may live
  # in an older/resolved thread, while `set_conversation` could have just picked
  # (or created) a different one for this webhook. Find the row globally, then
  # operate on its real `existing.conversation`.
  # Sender-agnostic existence check used to skip set_contact for removal
  # webhooks that have nothing to act on. Mirrors the inbox/in_reply_to scope
  # of `mark_existing_reaction_as_removed`.
  def existing_reaction_row?
    return false if @in_reply_to_external_id.blank?

    json_path = "(content_attributes#>>'{}')::jsonb"
    Message.where(inbox_id: inbox.id)
           .where("#{json_path}->>'is_reaction' = 'true'")
           .exists?(["#{json_path}->>'in_reply_to_external_id' = ?", @in_reply_to_external_id])
  end

  def mark_existing_reaction_as_removed # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    return if @in_reply_to_external_id.blank?

    json_path = "(content_attributes#>>'{}')::jsonb"
    # Scope by inbox so a colliding WhatsApp id from another inbox can't match
    # here and hand us back the wrong row.
    base = Message.where(inbox_id: inbox.id)
                  .where("#{json_path}->>'is_reaction' = 'true'")
                  .where("#{json_path}->>'in_reply_to_external_id' = ?", @in_reply_to_external_id)
    matches = if outgoing_echo
                # Multi-device: agent reacted via the connected phone, so the
                # local row has no agent (sender_id IS NULL) and is outgoing.
                base.where(sender_id: nil, sender_type: nil)
                    .where(message_type: Message.message_types[:outgoing])
              else
                base.where(sender: @contact)
              end
    # Active-only: when the only matches are already deleted, return nil so
    # the caller no-ops instead of re-deleting and bumping the conversation
    # for an echoed Chatwoot-originated removal.
    existing = matches.where.not(content: '')
                      .where("COALESCE(#{json_path}->>'deleted', 'false') != 'true'")
                      .reorder(created_at: :desc)
                      .first
    return if existing.nil?

    new_attrs = existing.content_attributes.merge('deleted' => true)
    existing.update!(content: '', content_attributes: new_attrs)
    target_conversation = existing.conversation
    # Refresh the chat list snapshot; cable MESSAGE_UPDATED only touches
    # chat.messages on the client, so the conversation card preview stays stale
    # without an explicit conversation.updated dispatch. Touch updated_at so
    # the frontend out-of-order guard can drop stale cables.
    target_conversation.update_columns(updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    target_conversation.dispatch_conversation_updated_event
  end

  # WhatsApp delivers messages it cannot render (e.g. coexistence companion-device syncs that
  # fail with error 131060) as type: unsupported with no content. We still persist a placeholder
  # so the contact/conversation isn't created "headless" and agents know to check the WhatsApp app.
  def create_unsupported_message(message)
    log_error(message) if error_webhook_event?(message)
    process_in_reply_to(message)
    create_message(message, source_id: message[:id])
    @message.content = I18n.t('conversations.messages.whatsapp.unsupported_message')
    @message.content_attributes = @message.content_attributes.merge(is_unsupported: true)
    @message.save!
  end

  def create_regular_message(message)
    create_message(message, source_id: message[:id])
    attach_files
    attach_location if message_type == 'location'
    @message.save!
  end

  def set_contact
    if outgoing_echo
      set_contact_from_echo
    else
      set_contact_from_message
    end
  end

  def set_conversation
    # A reaction annotates an existing message, so it must land in that message's
    # conversation, not follow the inbox reopen policy. Without this, reacting to a
    # message in a resolved thread (with lock_to_single_conversation off) would open
    # a stray blank conversation, or attach the reaction to the wrong active one.
    # Mirrors the inbox-scoped lookup used by the reaction-removal flow; falls back
    # to the normal logic when the target isn't stored locally.
    @conversation = conversation_for_reaction || conversation_by_inbox_config
    return backfill_first_touch_attribution if @conversation

    @conversation = ::Conversation.create!(conversation_params)
  end

  # When the inbound message reuses an existing thread (active/reopened), the
  # attribution conversation_params would have set on create never lands. Backfill
  # only the keys still missing so a genuine first touch is never overwritten.
  def backfill_first_touch_attribution
    attribution = { 'referral' => @referral, 'entry_point' => @entry_point }.compact
    existing_attributes = @conversation.additional_attributes || {}
    missing = attribution.reject { |key, _| existing_attributes.key?(key) }
    return if missing.blank?

    @conversation.update!(additional_attributes: existing_attributes.merge(missing))
  end

  def conversation_for_reaction
    return unless message_type == 'reaction'

    external_id = reaction_target_external_id
    return if external_id.blank?

    inbox.messages.find_by(source_id: external_id)&.conversation
  end

  # Cloud/Z-API set @in_reply_to_external_id before set_conversation; the Baileys
  # handler overrides this to read it straight from the raw webhook.
  def reaction_target_external_id
    @in_reply_to_external_id
  end

  def conversation_by_inbox_config
    # Reuse is scoped to the contact inbox that resolved this message, never to the contact. A contact
    # can hold unrelated WhatsApp identities in the same inbox, either from coexistence or from a
    # dashboard merge, and a contact wide lookup cannot tell them apart: it would answer one identity
    # through another one's source id. The conversation opened under a previous identity stays where it
    # is and remains reachable under previous conversations.
    #
    # Only where an identifier can be replied to, though. 360Dialog always sends the destination in
    # `to` and has no way to address one, so anchoring a thread there would produce a conversation
    # nobody can answer. That provider keeps the contact wide reuse it had, which lands every message
    # on the phone backed thread it can actually reply through. The legacy session providers
    # (Baileys, Z-API) take the same branch: their handlers set @contact_inbox, but they never carry
    # a BSUID, so the contact wide reuse is the behaviour they have always had.
    conversations = addressable_identifiers? ? @contact_inbox.conversations : @contact.conversations.where(inbox_id: @inbox.id)
    # if lock to single conversation is disabled, we will create a new conversation if previous conversation is resolved
    if @inbox.lock_to_single_conversation
      conversations.last
    else
      conversations.where.not(status: :resolved).last
    end
  end

  def attach_files
    return if %w[text button interactive location contacts reaction request_welcome unsupported].include?(message_type)

    attachment_payload = messages_data.first[message_type.to_sym]
    @message.content ||= attachment_payload[:caption]

    attachment_file = download_attachment_file(attachment_payload)
    return if attachment_file.blank?

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      file: {
        io: attachment_file,
        filename: attachment_payload[:filename].presence || attachment_file.original_filename,
        content_type: attachment_file.content_type
      },
      meta: ({ is_recorded_audio: true } if attachment_payload[:voice])
    )
  end

  def attach_location
    location = messages_data.first['location']
    location_name = (location['name'] ? "#{location['name']}, #{location['address']}" : '').first(255)
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_content_type(message_type),
      coordinates_lat: location['latitude'],
      coordinates_long: location['longitude'],
      fallback_title: location_name,
      external_url: location['url']
    )
  end

  def create_message(message, source_id: nil, content_attributes_source: message)
    @message = @conversation.messages.build(
      content: message_content(message),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: outgoing_echo ? :outgoing : :incoming,
      # Set status to :delivered for echo messages to prevent SendReplyJob from trying to send them
      status: outgoing_echo ? :delivered : :sent,
      sender: outgoing_echo ? nil : @contact,
      source_id: (source_id || message[:id]).to_s,
      content_attributes: message_content_attributes(content_attributes_source)
    )
  end

  def message_content_attributes(message)
    content_attrs = outgoing_echo ? { external_echo: true } : {}
    content_attrs[:in_reply_to] = in_reply_to_message_id if in_reply_to_message_id.present?
    content_attrs[:in_reply_to_external_id] = @in_reply_to_external_id if @in_reply_to_external_id.present?
    content_attrs[:external_created_at] = message[:timestamp].to_i
    content_attrs[:is_reaction] = true if message_type == 'reaction'
    referral = normalize_cloud_referral(message)
    content_attrs[:referral] = referral if referral.present?

    flow_response = message.dig(:interactive, :nfm_reply)
    if flow_response.present?
      content_attrs[:whatsapp_flow_response] = {
        name: flow_response[:name],
        body: flow_response[:body],
        response_json: parse_flow_response_json(flow_response[:response_json])
      }.compact
    end

    content_attrs
  end

  def update_contact_with_profile_name(contact_params)
    profile_name = contact_params.dig(:profile, :name)
    return if profile_name.blank?
    return if @contact.name == profile_name

    # Only update if current name exactly matches a phone number candidate
    return unless contact_name_matches_phone_number?

    @contact.update!(name: profile_name)
  end

  def contact_name_matches_phone_number?
    return false if (message_phone_number = whatsapp_phone_number(messages_data.first[:from])).blank?

    phone_number_candidates(message_phone_number).any? do |number|
      phone_number = "+#{number}"
      formatted_phone_number = TelephoneNumber.parse(phone_number).international_number
      @contact.name == phone_number || @contact.name == formatted_phone_number
    end
  end
end

Whatsapp::IncomingMessageBaseService.prepend_mod_with('Whatsapp::IncomingMessageBaseService')
