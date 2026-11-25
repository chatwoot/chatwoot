module Whatsapp::BaileysHandlers::MessagesUpdate
  include Whatsapp::BaileysHandlers::Helpers
  include BaileysHelper

  class MessageNotFoundError < StandardError; end

  private

  def process_messages_update
    updates = processed_params[:data]
    updates.each do |update|
      @message = nil
      @raw_message = update

      next handle_update if incoming?

      # NOTE: Shared lock with Whatsapp::SendOnWhatsappService
      # Avoids race conditions when sending messages.
      with_baileys_channel_lock_on_outgoing_message(inbox.channel.id) { handle_update }
    end
  end

  def handle_update
    raise MessageNotFoundError unless find_message_by_source_id(raw_message_id)

    update_status if @raw_message.dig(:update, :status).present?
    handle_edited_content if @raw_message.dig(:update, :message).present?
  end

  def update_status
    status = status_mapper
    update_last_seen_at if incoming? && status == 'read'
    # Messages::StatusUpdateService refuses an unknown status and a move backwards, but lets
    # any message become `failed`, and a message the contact has read cannot have failed.
    return if @message.status == 'read'

    # The service is also what clears external_error when a message leaves `failed`;
    # writing the status here instead left a delivered message showing the error of an
    # earlier attempt.
    error = extract_external_error if status == 'failed'
    Messages::StatusUpdateService.new(@message, status, error).perform
  end

  def extract_external_error
    stub = Array(@raw_message.dig(:update, :messageStubParameters))
    return if stub.empty?

    code, description = stub
    description.present? ? "#{description} (#{code})" : "WhatsApp error #{code}"
  end

  def status_mapper
    # NOTE: Baileys status codes vs. Chatwoot support:
    #  - (0) ERROR         → (3) failed
    #  - (1) PENDING       → (0) sent
    #  - (2) SERVER_ACK    → (0) sent
    #  - (3) DELIVERY_ACK  → (1) delivered
    #  - (4) READ          → (2) read
    #  - (5) PLAYED        → (unsupported: PLAYED)
    # For details: https://github.com/WhiskeySockets/Baileys/blob/v6.7.16/WAProto/index.d.ts#L36694
    status = @raw_message.dig(:update, :status)
    case status
    when 0
      'failed'
    when 1, 2
      'sent'
    when 3
      'delivered'
    when 4
      'read'
    when 5
      Rails.logger.warn 'Baileys unsupported message update status: PLAYED(5)'
      nil
    else
      Rails.logger.warn "Baileys unsupported message update status: #{status}"
      nil
    end
  end

  # Skipped for this app's own receipt echoed back by the provider: see
  # Whatsapp::SelfReadReceipts.
  def update_last_seen_at
    conversation = @message.conversation
    return if acknowledged_in(conversation).include?(raw_message_id)

    to_update = { agent_last_seen_at: Time.current }
    to_update[:assignee_last_seen_at] = Time.current if conversation.assignee_id.present?

    conversation.update_columns(to_update) # rubocop:disable Rails/SkipsModelValidations
  end

  # Asked for the whole webhook at once, like the session handler does for a receipt: this
  # payload is a batch too, and a lookup per update would put a Redis round trip on each one.
  def acknowledged_in(conversation)
    @acknowledged_in ||= {}
    @acknowledged_in[conversation.id] ||= Whatsapp::SelfReadReceipts.acknowledged(conversation, read_receipt_ids)
  end

  def read_receipt_ids
    @read_receipt_ids ||= Array(processed_params[:data]).filter_map do |update|
      update.dig(:key, :id) if update.dig(:key, :fromMe).blank? && update.dig(:update, :status) == 4
    end
  end

  def handle_edited_content
    edited_at = edit_timestamp_ms
    @raw_message = @raw_message.dig(:update, :message, :editedMessage)
    content = message_content

    # `nil` means no readable content; an empty string is a real edit that cleared
    # a media caption, and dropping it would leave the old caption on screen.
    if content.nil?
      Rails.logger.warn 'No valid message content found in the edit event'
      return
    end

    # Read and write under the row lock, the same way the session layer applies an
    # edit: during a force restart or a cluster handoff the discarded connection
    # keeps draining its webhooks on purpose while the replacement already handles
    # new events, so two edits of one message can be applied at once. A
    # read-compare-write outside the lock lets both pass the staleness check and the
    # older one land last.
    @message.with_lock do
      next if stale_edit?(edited_at)

      # Preserve original previous_content if message was already edited
      previous_content_to_save = @message.is_edited ? @message.previous_content : @message.content
      attrs = { content: content, is_edited: true, previous_content: previous_content_to_save }
      # Only when this edit carries one: writing nil would erase the watermark a
      # later out-of-order edit is checked against.
      attrs[:edited_at] = edited_at if edited_at.present?
      @message.update!(attrs)
    end
  end

  # Older than the edit already stored, so it must not overwrite it. The comparison
  # is on the provider's own clock rather than on arrival, since arrival is the
  # thing that is out of order. Ties pass: WhatsApp stamps edits in whole seconds,
  # so two edits inside one second carry no order to respect. An edit with no
  # timestamp passes too -- refusing it would drop the edit outright, which is worse
  # than applying it out of order.
  def stale_edit?(edited_at)
    edited_at.present? && @message.edited_at.present? && edited_at < @message.edited_at
  end

  # The provider stamps edits in whole seconds, on both the encrypted and the
  # plaintext path, and a protobuf 64-bit field reaches us either as a number or as
  # a `{ low, high }` hash — which is what the shared helper is for. `edited_at`
  # holds milliseconds, which is what the session layer writes and what the model
  # documents, so the two providers stay comparable.
  def edit_timestamp_ms
    timestamp = @raw_message.dig(:update, :messageTimestamp)
    return if timestamp.blank?

    baileys_extract_message_timestamp(timestamp) * 1000
  end
end
