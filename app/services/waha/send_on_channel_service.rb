class Waha::SendOnChannelService
  pattr_initialize [:message!]

  def perform
    validate_target_channel
    return unless outgoing_message?
    return if invalid_message?

    perform_reply
  end

  private

  delegate :conversation, to: :message
  delegate :contact, :contact_inbox, :inbox, to: :conversation
  delegate :channel, to: :inbox

  def channel_class
    Channel::WhatsappUnofficial
  end

  def perform_reply
    phone_number = contact_inbox.source_id
    
    # Extract attachment URLs if message has attachments
    image_url = nil
    document_url = nil
    video_url = nil
    
    if message.attachments.present?
      attachment = message.attachments.first
      case attachment.file_type
      when 'image'
        image_url = attachment.download_url
      when 'file'
        document_url = attachment.download_url
      when 'video'
        video_url = attachment.download_url
      end
    end

    response = channel.send_message(
      phone_number: phone_number,
      message: message.content,
      image_url: image_url,
      document_url: document_url,
      video_url: video_url
    )

    # Update message with source_id if successful
    if response && response.dig('data', 'message_id').present?
      message.update!(source_id: response.dig('data', 'message_id'))
    end
  end

  def outgoing_message_originated_from_channel?
    message.source_id.present?
  end

  def outgoing_message?
    message.outgoing? || message.template?
  end

  def invalid_message?
    message.private? || outgoing_message_originated_from_channel?
  end

  def validate_target_channel
    raise 'Invalid channel service was called' if inbox.channel.class != channel_class
  end
end