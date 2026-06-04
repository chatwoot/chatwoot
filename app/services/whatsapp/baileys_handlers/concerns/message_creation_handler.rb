module Whatsapp::BaileysHandlers::Concerns::MessageCreationHandler
  extend ActiveSupport::Concern

  private

  def build_and_save_message(conversation:, sender:, attach_media: false)
    @message = conversation.messages.build(
      content: message_content,
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      source_id: raw_message_id,
      sender: incoming? ? sender : nil,
      message_type: incoming? ? :incoming : :outgoing,
      content_attributes: build_message_content_attributes
    )

    attach_media_to_message if attach_media

    @message.save!

    inbox.channel.received_messages([@message], conversation) if incoming?

    @message
  end

  def build_message_content_attributes
    type = message_type
    msg = unwrap_ephemeral_message(@raw_message[:message])
    content_attributes = { external_created_at: baileys_extract_message_timestamp(@raw_message[:messageTimestamp]) }
    content_attributes[:external_sender_name] = 'WhatsApp' unless incoming?

    if type == 'reaction'
      content_attributes[:in_reply_to_external_id] = msg.dig(:reactionMessage, :key, :id)
      content_attributes[:is_reaction] = true
    elsif reply_to_message_id
      content_attributes[:in_reply_to_external_id] = reply_to_message_id
    elsif type == 'unsupported'
      content_attributes[:is_unsupported] = true
    end

    content_attributes
  end

  def attach_media_to_message
    attachment_file = download_attachment_file
    msg = unwrap_ephemeral_message(@raw_message[:message])

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
    msg = unwrap_ephemeral_message(@raw_message[:message])
    filename = msg.dig(:documentMessage, :fileName) || msg.dig(:documentWithCaptionMessage, :message, :documentMessage, :fileName)
    return filename if filename.present?

    ext = ".#{message_mimetype.split(';').first.split('/').last}" if message_mimetype.present?
    "#{file_content_type}_#{raw_message_id}_#{Time.current.strftime('%Y%m%d')}#{ext}"
  end

  def should_attach_media?
    %w[image file video audio sticker].include?(message_type)
  end
end
