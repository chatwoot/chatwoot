module Whatsapp::ZapiHandlers::ReceivedCallback # rubocop:disable Metrics/ModuleLength
  include Whatsapp::ZapiHandlers::Helpers

  private

  def process_received_callback # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    @raw_message = processed_params
    @message = nil
    @contact_inbox = nil
    @contact = nil
    @lock_acquired = false

    return unless should_process_message?
    return if find_message_by_source_id(raw_message_id)

    # Atomically acquire lock to prevent race conditions with concurrent webhook deliveries
    @lock_acquired = acquire_message_processing_lock
    return unless @lock_acquired

    return handle_edited_message if @raw_message[:isEdit]

    with_zapi_contact_lock(@raw_message[:phone]) do
      set_contact

      unless @contact
        Rails.logger.warn "Contact not found for message: #{raw_message_id}"
        return
      end

      # Reaction removals don't produce a new Message row — handle them before
      # set_conversation so a blank webhook can't open/create a stray thread.
      next mark_existing_reaction_as_removed if reaction_removal?

      next if Whatsapp::BlockedSender.silenced?(@contact, from_me: !incoming_message?)

      set_conversation
      handle_create_message
    end
  ensure
    clear_message_source_id_from_redis if @lock_acquired
  end

  def should_process_message?
    !@raw_message[:isGroup] &&
      !@raw_message[:isNewsletter] &&
      !@raw_message[:broadcast] &&
      !@raw_message[:isStatusReply] &&
      !@raw_message.key?(:notification)
  end

  def message_type # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    return 'text' if @raw_message.key?(:text)
    return 'reaction' if @raw_message.key?(:reaction)
    return 'audio' if @raw_message.key?(:audio)
    return 'image' if @raw_message.key?(:image)
    return 'sticker' if @raw_message.key?(:sticker)
    return 'video' if @raw_message.key?(:video)
    return 'file' if @raw_message.key?(:document)
    return 'contact' if @raw_message.key?(:contact)

    'unsupported'
  end

  def message_content
    case message_type
    when 'text'
      @raw_message.dig(:text, :message)
    when 'image'
      @raw_message.dig(:image, :caption)
    when 'video'
      @raw_message.dig(:video, :caption)
    when 'file'
      @raw_message.dig(:document, :fileName)
    when 'reaction'
      @raw_message.dig(:reaction, :value)
    when 'contact'
      @raw_message.dig(:contact, :displayName)
    end
  end

  def contact_name
    @raw_message[:senderName] || @raw_message[:chatName] || @raw_message[:phone]
  end

  def set_contact # rubocop:disable Metrics/MethodLength
    push_name = contact_name
    source_id = @raw_message[:chatLid].to_s.gsub(/[^\d]/, '')
    identifier = @raw_message[:chatLid]

    contact_attributes = { name: push_name, identifier: identifier }

    unless @raw_message[:phone].ends_with?('@lid')
      contact_attributes[:phone_number] = "+#{@raw_message[:phone]}"
      Whatsapp::ContactInboxConsolidationService.new(
        inbox: inbox,
        phone: @raw_message[:phone],
        lid: source_id,
        identifier: identifier
      ).perform
    end

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: inbox,
      contact_attributes: contact_attributes
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact

    @contact.update!(name: push_name) if @contact.name == @raw_message[:phone]
    update_contact_phone_number
    try_update_contact_avatar
  end

  def update_contact_phone_number
    return if @contact.phone_number.present?
    return if @raw_message[:phone].ends_with?('@lid')

    @contact.update!(phone_number: "+#{@raw_message[:phone]}")
  end

  def try_update_contact_avatar
    avatar_url = @raw_message[:senderPhoto] || @raw_message[:photo]
    return unless avatar_url.present? && avatar_url.start_with?('http')

    Avatar::AvatarFromUrlJob.perform_later(@contact, avatar_url)
  end

  def handle_create_message
    if message_type == 'contact'
      create_contact_message
    else
      create_message(attach_media: %w[image sticker file video audio].include?(message_type))
    end
  end

  def reaction_removal?
    message_type == 'reaction' && message_content.blank?
  end

  # Z-API delivers a reaction removal as a webhook with empty value. Our schema
  # keeps a single Message row per (target, sender) toggling `deleted` on it,
  # so we update that row in place.
  #
  # `fromMe` removals can come from two paths and we want both handled:
  # - Chatwoot-originated echo: the controller already toggled the row to
  #   deleted, so the active-first lookup finds nothing and this no-ops.
  # - Multi-device removal (agent un-reacts from the connected phone): the row
  #   is still active and stored sender-less outgoing, so we mark it deleted.
  # Lookup is intentionally NOT scoped to `@conversation`: the reaction may
  # live in an older/resolved thread, while `set_conversation` could have
  # picked (or created) a different one for this webhook. Find the row first,
  # then operate on its real `existing.conversation`.
  def mark_existing_reaction_as_removed # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    target_external_id = @raw_message.dig(:reaction, :referencedMessage, :messageId)
    return if target_external_id.blank?

    json_path = "(content_attributes#>>'{}')::jsonb"
    # Scope by inbox: the senderless outgoing branch would otherwise match any
    # reaction with the same provider message id, and two inboxes that ever
    # receive colliding WhatsApp ids would step on each other's rows.
    base = Message.where(inbox_id: inbox.id)
                  .where("#{json_path}->>'is_reaction' = 'true'")
                  .where("#{json_path}->>'in_reply_to_external_id' = ?", target_external_id)
    matches = if incoming_message?
                base.where(sender: @contact)
              else
                # Multi-device: agent reacted via the connected phone, so the
                # local row has no agent (sender_id IS NULL) and is outgoing.
                base.where(sender_id: nil, sender_type: nil)
                    .where(message_type: Message.message_types[:outgoing])
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

  def create_contact_message
    contact_data = @raw_message[:contact]
    phones = contact_data[:phones] || []
    phones = ['Phone number is not available'] if phones.blank?

    phones.each do |phone|
      build_message
      attach_contact(phone, contact_data)
      @message.save!
    end

    notify_channel_of_received_message
  end

  def create_message(attach_media: false)
    build_message
    handle_attach_media if attach_media
    @message.save!
    notify_channel_of_received_message
  end

  def build_message
    @message = @conversation.messages.build(
      content: message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      source_id: raw_message_id,
      sender: incoming_message? ? @contact : nil,
      message_type: incoming_message? ? :incoming : :outgoing,
      content_attributes: message_content_attributes
    )
  end

  def notify_channel_of_received_message
    inbox.channel.received_messages([@message], @conversation) if incoming_message?
  end

  def message_content_attributes
    type = message_type
    content_attributes = { external_created_at: @raw_message[:momment] / 1000 }
    content_attributes[:external_sender_name] = 'WhatsApp' unless incoming_message?

    if type == 'reaction'
      content_attributes[:in_reply_to_external_id] = @raw_message.dig(:reaction, :referencedMessage, :messageId)
      content_attributes[:is_reaction] = true
    elsif type == 'unsupported'
      content_attributes[:is_unsupported] = true
    end

    content_attributes[:in_reply_to_external_id] = @raw_message[:referenceMessageId] if @raw_message[:referenceMessageId].present?

    content_attributes
  end

  def attach_contact(phone, contact_data)
    name_parts = contact_data[:displayName]&.split || []

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: :contact,
      fallback_title: phone.to_s,
      meta: {
        firstName: name_parts.first,
        lastName: name_parts.drop(1).join(' ')
      }.compact_blank
    )
  end

  def handle_attach_media
    attachment_file = download_attachment_file

    attachment = @message.attachments.build(
      account_id: @message.account_id,
      file_type: file_content_type.to_s,
      file: { io: attachment_file, filename: filename, content_type: message_mimetype }
    )

    attachment.meta = { is_recorded_audio: true } if @raw_message.dig(:audio, :ptt)
  rescue Down::Error => e
    @message.update!(is_unsupported: true)
    Rails.logger.error "Failed to download attachment for message #{raw_message_id}: #{e.message}"
  end

  def download_attachment_file
    media_url = case message_type
                when 'image'
                  @raw_message.dig(:image, :imageUrl)
                when 'sticker'
                  @raw_message.dig(:sticker, :stickerUrl)
                when 'audio'
                  @raw_message.dig(:audio, :audioUrl)
                when 'video'
                  @raw_message.dig(:video, :videoUrl)
                when 'file'
                  @raw_message.dig(:document, :documentUrl)
                end

    Down.download(media_url)
  end

  def filename
    case message_type
    when 'file'
      @raw_message.dig(:document, :fileName)
    else
      ext = ".#{message_mimetype.split(';').first.split('/').last}" if message_mimetype.present?
      "#{file_content_type}_#{raw_message_id}_#{Time.current.strftime('%Y%m%d')}#{ext}"
    end
  end

  def file_content_type
    return :image if %w[image sticker].include?(message_type)
    return :video if message_type == 'video'
    return :audio if message_type == 'audio'

    :file
  end

  def message_mimetype
    case message_type
    when 'image'
      @raw_message.dig(:image, :mimeType)
    when 'sticker'
      @raw_message.dig(:sticker, :mimeType)
    when 'video'
      @raw_message.dig(:video, :mimeType)
    when 'audio'
      @raw_message.dig(:audio, :mimeType)
    when 'file'
      @raw_message.dig(:document, :mimeType)
    end
  end

  def handle_edited_message
    @message = find_message_by_source_id(@raw_message[:messageId])
    return unless @message

    # Preserve original previous_content if message was already edited
    previous_content_to_save = @message.is_edited ? @message.previous_content : @message.content
    @message.update!(
      content: message_content,
      is_edited: true,
      previous_content: previous_content_to_save
    )
  end
end
