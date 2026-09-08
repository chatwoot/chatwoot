class ZaloOa::SendOnZaloOaService < Base::SendOnChannelService
  private

  def channel_class
    Channel::ZaloOa
  end

  def perform_reply
    message.attachments.present? ? send_attachments : send_text
  rescue ZaloOa::MessageSender::WindowError, ZaloOa::MessageSender::PermanentError => e
    message.update!(status: :failed, external_error: e.message)
  end

  def send_text
    return if message.outgoing_content.blank?

    record_external_id(sender.send_text(user_id, message.outgoing_content, quoted_message_id))
  end

  # Zalo has no multi-attachment send, so each attachment becomes its own Zalo message. Ids are
  # recorded as each send succeeds, so a partial failure keeps what was delivered, a retry resumes
  # instead of re-sending, and ZaloOa::IncomingMessageService can match every echo.
  def send_attachments
    caption = external_message_ids.empty? ? message.outgoing_content : nil
    message.attachments.drop(external_message_ids.size).each do |attachment|
      record_external_id(sender.send_attachment(user_id, attachment, caption))
      caption = nil # only the first attachment carries the caption
    end
  end

  # Each attachment is its own Zalo message, and record_external_id writes source_id after the
  # first one succeeds. A partially-sent message therefore legitimately carries a source_id while
  # still having attachments to deliver, so the base class would otherwise skip the retry.
  # external_message_ids is only ever populated by our own sends, so an inbound oa_send_* echo
  # (source_id set, no recorded ids) still short-circuits correctly and cannot loop.
  def outgoing_message_originated_from_channel?
    return false if partially_sent?

    super
  end

  def partially_sent?
    external_message_ids.present? && external_message_ids.size < message.attachments.size
  end

  def external_message_ids
    message.content_attributes['external_message_ids'] || []
  end

  def record_external_id(zalo_message_id)
    return if zalo_message_id.blank?

    ids = external_message_ids + [zalo_message_id]
    message.update!(
      source_id: ids.first,
      content_attributes: message.content_attributes.merge('external_message_ids' => ids)
    )
    # Zalo echoes our own sends back as oa_send_* events within seconds; this lets
    # ZaloOa::IncomingMessageService recognise them without scanning the messages table.
    ::Redis::Alfred.setex(format(::Redis::Alfred::ZALO_OA_SENT_MESSAGE, inbox_id: inbox.id, zalo_message_id: zalo_message_id), true)
  end

  def sender
    @sender ||= ZaloOa::MessageSender.new(channel: channel)
  end

  def user_id
    contact_inbox.source_id
  end

  def quoted_message_id
    message.content_attributes['in_reply_to_external_id']
  end
end
