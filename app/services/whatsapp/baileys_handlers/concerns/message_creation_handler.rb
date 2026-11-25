module Whatsapp::BaileysHandlers::Concerns::MessageCreationHandler # rubocop:disable Metrics/ModuleLength
  extend ActiveSupport::Concern

  private

  def build_and_save_message(conversation:, sender:, attach_media: false)
    return build_and_save_contact_messages(conversation: conversation, sender: sender) if message_type == 'contact'

    @message = conversation.messages.build(content: message_content, **webhook_message_attributes(sender))

    attach_media_to_message if attach_media
    attach_location_to_message if message_type == 'location'

    @message.save!

    inbox.channel.received_messages([@message], conversation) if incoming?

    @message
  end

  # Columns shared by every message built from the current webhook: an incoming message keeps its
  # sender, while a message the session sent (echoed back by WhatsApp) is stored sender-less.
  def webhook_message_attributes(sender)
    {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      source_id: raw_message_id,
      sender: incoming? ? sender : nil,
      message_type: incoming? ? :incoming : :outgoing,
      content_attributes: build_message_content_attributes
    }
  end

  # WhatsApp echoes back every message the session sends, including the ones Chatwoot itself
  # dispatched. Those echoes are normally recognized by `source_id`, which is only written from the
  # send response — when that response is lost and the job retries, the echo carries an id Chatwoot
  # never saw and would be stored as a new sender-less outgoing message, rendered as if an agent had
  # replied from the phone. Baileys sends reserve their WhatsApp id before the request
  # (`reserve_source_id`), so match on that instead and just fill in the `source_id` the response
  # never delivered.
  #
  # Runs before the conversation is picked: a delayed echo whose original thread was resolved
  # meanwhile would otherwise reopen it or open a stray new one just to hold a message that is
  # already stored. The lookup spans every conversation the contact has in this inbox, since that
  # is where the sent message can be, and answers with the conversation actually holding it.
  def confirm_reserved_outgoing_message(contact)
    return false if incoming?

    reserved = Message.where(conversation_id: contact.conversations.where(inbox_id: inbox.id).select(:id))
                      .where(message_type: :outgoing)
                      .where("(content_attributes#>>'{}')::jsonb->>'pending_source_id' = ?", raw_message_id)
                      .first
    return false if reserved.nil?

    confirm_source_id(reserved) if reserved.source_id.blank?
    @message = reserved
    @conversation = reserved.conversation
    true
  end

  # Mirrors Whatsapp::SendOnWhatsappService#persist_source_id: the id the send never got to store is
  # what a revoke needs, so a message deleted while that send was in flight can only be taken off the
  # contact's phone once this echo supplies it.
  # Through SourceIdReservation, exactly like the session layer's EchoMatcher, because
  # filling source_id now means two things and not one: it decides who owes the revoke,
  # and it retires a send failure recorded while the id was still blank. Writing the
  # column directly here left a message that exhausted its retries before this echo
  # arrived sitting on `failed` with a Retry button — and Retry clears the reservation and
  # sends a fresh id, which is the duplicate the reservation exists to prevent.
  def confirm_source_id(reserved)
    return if raw_message_id.blank?
    return unless ::Whatsapp::Session::Outbound::SourceIdReservation.assign(
      reserved, { source_id: raw_message_id }
    ) == :revoke

    ::Messages::DeleteOnChannelJob.perform_later(reserved.id)
  end

  # Mirrors the Cloud provider (create_contact_messages): one message per shared
  # contact, each with a native contact attachment, so the dashboard renders them
  # in the contact bubble instead of as plain text.
  def build_and_save_contact_messages(conversation:, sender:)
    messages = baileys_contacts.filter_map { |contact| build_contact_message(conversation, sender, contact) }
    inbox.channel.received_messages(messages, conversation) if incoming? && messages.any?
    @message = messages.last
  end

  def build_contact_message(conversation, sender, contact)
    fields = baileys_contact_fields(contact)
    return if fields[:phone].blank? && fields[:name].blank?

    message = conversation.messages.build(content: baileys_contact_line(contact), **webhook_message_attributes(sender))
    attach_contact_card(message, fields)
    message.save!
    message
  end

  def attach_contact_card(message, fields)
    message.attachments.build(
      account_id: inbox.account_id, file_type: :contact,
      fallback_title: fields[:phone].presence || fields[:name], meta: { firstName: fields[:name] }.compact
    )
  end

  # WhatsApp delivers a reaction removal as a fresh message with empty text.
  # Our schema keeps a single Message row per (target, sender) and toggles
  # `deleted` on it, so we look up that row and mark it removed instead of
  # creating a duplicate empty Message that the chat list would have to filter.
  #
  # `fromMe` removals can come from two paths and we want both handled:
  # - Chatwoot-originated echo: the controller already toggled the row to
  #   deleted, so the active-only lookup finds nothing and this no-ops.
  # - Multi-device removal (agent un-reacts from the connected phone): the
  #   row is still active and stored sender-less outgoing, so we mark it
  #   deleted.
  # Lookup is intentionally NOT scoped to the inbound conversation: the
  # original reaction may live in an older/resolved thread, while the inbound
  # flow could have picked (or created) a different one. Find the row first,
  # then operate on its real `existing.conversation`.
  def mark_existing_reaction_as_removed(sender:)
    target_external_id = unwrap_message_content(@raw_message[:message]).dig(:reactionMessage, :key, :id)
    return if target_external_id.blank?

    existing = find_existing_reaction(sender, target_external_id)
    return if existing.nil?

    new_attrs = existing.content_attributes.merge('deleted' => true)
    existing.update!(content: '', content_attributes: new_attrs)
    target_conversation = existing.conversation
    # Refresh the chat list snapshot of `last_non_activity_message`; the cable
    # MESSAGE_UPDATED event only refreshes chat.messages on the client, so
    # without this the preview can stay pointed at the pre-removal reaction.
    # Touch updated_at so the frontend out-of-order guard can drop stale cables.
    target_conversation.update_columns(updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    target_conversation.dispatch_conversation_updated_event
    existing
  end

  def find_existing_reaction(sender, target_external_id)
    json_path = "(content_attributes#>>'{}')::jsonb"
    # Scope by inbox: the senderless outgoing branch would otherwise match any
    # reaction with the same provider message id, and two inboxes that ever
    # receive colliding WhatsApp ids would step on each other's rows.
    base = Message.where(inbox_id: inbox.id)
                  .where("#{json_path}->>'is_reaction' = 'true'")
                  .where("#{json_path}->>'in_reply_to_external_id' = ?", target_external_id)
    matches = if incoming?
                base.where(sender: sender)
              else
                # Multi-device: agent reacted via the connected phone, so the
                # local row has no agent (sender_id IS NULL) and is outgoing.
                base.where(sender_id: nil, sender_type: nil)
                    .where(message_type: Message.message_types[:outgoing])
              end
    # Active-only: when the only matches are already deleted, this returns nil
    # so the caller no-ops instead of re-deleting and bumping the conversation
    # for an echoed Chatwoot-originated removal.
    matches.where.not(content: '')
           .where("COALESCE(#{json_path}->>'deleted', 'false') != 'true'")
           .reorder(created_at: :desc)
           .first
  end

  def build_message_content_attributes
    type = message_type
    msg = unwrap_message_content(@raw_message[:message])
    content_attributes = { external_created_at: baileys_extract_message_timestamp(@raw_message[:messageTimestamp]) }
    content_attributes[:external_sender_name] = 'WhatsApp' unless incoming?

    if type == 'reaction'
      content_attributes[:in_reply_to_external_id] = msg.dig(:reactionMessage, :key, :id)
      content_attributes[:is_reaction] = true
    elsif reply_to_message_id
      content_attributes[:in_reply_to_external_id] = reply_to_message_id
    elsif type.in?(%w[unsupported masked view_once])
      add_contentless_attributes(content_attributes, type)
    end

    add_rich_content_attributes(content_attributes, msg) if type == 'rich'

    referral = normalize_baileys_referral(message_context_info)
    content_attributes[:referral] = referral if referral.present?

    content_attributes
  end

  # A row with nothing to render. All kinds go through the unsupported bubble, which
  # is what already strips the reply/reaction affordances an empty row must not offer;
  # the masked and view-once flags only swap the copy for one that names why WhatsApp
  # withheld the content instead of blaming a message type we failed to parse.
  def add_contentless_attributes(content_attributes, type)
    content_attributes[:is_unsupported] = true
    content_attributes[:is_masked] = true if type == 'masked'
    content_attributes[:is_view_once] = true if type == 'view_once'
  end

  # Persists the structured card payload. A rich shape with neither text/buttons
  # nor a media header falls back to unsupported (the previous empty-bubble
  # behavior) and is logged to capture real shapes. A media-only header still
  # renders via the attached media, so it is not flagged unsupported.
  def add_rich_content_attributes(content_attributes, msg)
    rich = Whatsapp::Baileys::RichMessageParser.new(msg).parse
    content_attributes[:rich] = rich if rich.present?
    return if rich.present? || should_attach_media?

    content_attributes[:is_unsupported] = true
    Rails.logger.info("[Baileys] rich message fell back to unsupported: keys=#{msg.keys}")
  end

  def attach_media_to_message
    attachment_file = download_attachment_file
    msg = unwrap_message_content(@raw_message[:message])

    attachment = @message.attachments.build(
      account_id: @message.account_id,
      file_type: file_content_type.to_s,
      file: { io: attachment_file, filename: build_attachment_filename, content_type: message_mimetype }
    )
    attachment.meta = { is_recorded_audio: true } if msg.dig(:audioMessage, :ptt)
  rescue Down::Error => e
    @message.is_unsupported = true
    Rails.logger.error "Failed to download attachment for message #{raw_message_id}: #{e.message}"
  end

  def download_attachment_file
    Down.download(
      inbox.channel.media_url(@raw_message.dig(:key, :id)),
      headers: inbox.channel.api_headers
    )
  end

  def build_attachment_filename
    msg = unwrap_message_content(@raw_message[:message])
    filename = msg.dig(:documentMessage, :fileName) ||
               msg.dig(:documentWithCaptionMessage, :message, :documentMessage, :fileName) ||
               rich_media_header&.dig(:node, :fileName)
    return filename if filename.present?

    ext = ".#{message_mimetype.split(';').first.split('/').last}" if message_mimetype.present?
    "#{file_content_type}_#{raw_message_id}_#{Time.current.strftime('%Y%m%d')}#{ext}"
  end

  # Location carries no downloadable bytes; persist coordinates as a native
  # location attachment so the dashboard renders it in the map bubble.
  def attach_location_to_message
    loc = unwrap_message_content(@raw_message[:message])
    loc = loc[:locationMessage] || loc[:liveLocationMessage]
    return if loc.blank?

    name = [loc[:name], loc[:address]].compact_blank.join(', ')
    @message.attachments.build(
      account_id: @message.account_id,
      file_type: :location,
      coordinates_lat: loc[:degreesLatitude],
      coordinates_long: loc[:degreesLongitude],
      fallback_title: name.presence,
      external_url: loc[:url]
    )
  end

  def should_attach_media?
    %w[image file video audio sticker].include?(message_type) || rich_media_header.present?
  end
end
