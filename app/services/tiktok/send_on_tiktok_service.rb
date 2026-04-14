class Tiktok::SendOnTiktokService < Base::SendOnChannelService
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
  end

  def send_message
    tt_conversation_id = message.conversation[:additional_attributes]['conversation_id']
    tt_referenced_message_id = message.content_attributes['in_reply_to_external_id']

    if message.attachments.any?
      tiktok_client.send_media_message(tt_conversation_id, message.attachments.first, referenced_message_id: tt_referenced_message_id)
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
