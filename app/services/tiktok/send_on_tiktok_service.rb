class Tiktok::SendOnTiktokService < Base::SendOnChannelService
  SUPPORTED_IMAGE_CONTENT_TYPES = %w[image/jpeg image/png].freeze
  MAX_IMAGE_SIZE = 3.megabytes

  private

  def channel_class
    Channel::Tiktok
  end

  def perform_reply
    validate_message_support!
    message_id = send_message

    message.update!(source_id: message_id)
    Messages::StatusUpdateService.new(message, 'delivered').perform
  rescue StandardError => e
    Rails.logger.error "Failed to send Tiktok message: #{e.message}"
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def validate_message_support!
    return unless message.attachments.any?

    raise 'Sending attachments with text is not supported on TikTok.' if message.outgoing_content.present?
    raise 'Sending multiple attachments in a single TikTok message is not supported.' unless message.attachments.one?

    validate_attachment_support!(message.attachments.first)
  end

  def validate_attachment_support!(attachment)
    raise 'Sending image attachments is not supported for this TikTok conversation.' unless image_send_capable?
    raise 'Only image attachments are supported on TikTok.' unless attachment.image?
    raise 'TikTok supports only JPG and PNG images.' unless SUPPORTED_IMAGE_CONTENT_TYPES.include?(attachment.file.content_type)
    raise 'TikTok image attachments must be smaller than 3 MB.' if attachment.file.byte_size > MAX_IMAGE_SIZE
  end

  def image_send_capable?
    message.conversation.additional_attributes.dig('tiktok_capabilities', 'image_send') != false
  end

  def send_message
    tt_conversation_id = message.conversation[:additional_attributes]['conversation_id']
    tt_referenced_message_id = message.content_attributes['in_reply_to_external_id']

    if message.attachments.any?
      tiktok_client.send_media_message(tt_conversation_id, message.attachments.first)
    else
      tiktok_client.send_text_message(tt_conversation_id, message.outgoing_content, referenced_message_id: tt_referenced_message_id)
    end
  end

  def tiktok_client
    @tiktok_client ||= Tiktok::Client.new(business_id: channel.business_id, access_token: channel.validated_access_token)
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end
end
