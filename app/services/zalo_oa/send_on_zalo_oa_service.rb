class ZaloOa::SendOnZaloOaService < Base::SendOnChannelService
  private

  def channel_class
    Channel::ZaloOa
  end

  def perform_reply
    user_id = get_user_id
    return unless user_id

    if message.attachments.any?
      send_with_attachments(user_id)
    else
      send_text_message(user_id)
    end
  end

  def send_text_message(user_id)
    response = channel.send_message(user_id, message.outgoing_content)

    if response && response['error'] == 0
      Messages::StatusUpdateService.new(message, 'delivered').perform
    else
      error_message = response&.dig('message') || 'Unknown error'
      Messages::StatusUpdateService.new(message, 'failed', error_message).perform
    end
  rescue StandardError => e
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def send_with_attachments(user_id)
    send_text_message(user_id) if message.outgoing_content.present?

    message.attachments.each do |attachment|
      send_attachment(user_id, attachment)
    end
  end

  def send_attachment(user_id, attachment)
    response = channel.send_message(user_id, attachment.file_type, attachments: [attachment])

    if response && response['error'] == 0
      Messages::StatusUpdateService.new(message, 'delivered').perform
    else
      error_message = response&.dig('message') || 'Unknown error'
      Messages::StatusUpdateService.new(message, 'failed', error_message).perform
    end
  rescue StandardError => e
    Messages::StatusUpdateService.new(message, 'failed', e.message).perform
  end

  def get_user_id
    contact_inbox.source_id || conversation.additional_attributes['zalo_user_id']
  end
end
