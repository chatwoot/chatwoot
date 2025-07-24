class Waha::SendOnWahaService < Waha::SendOnChannelService
  private

  def channel_class
    Channel::WhatsappUnofficial
  end

  def perform_reply
    begin
      response = channel.send_message(**message_params)
    rescue WhatsappUnofficial::Error => e
      message.update!(status: :failed, external_error: e.message)
      return
    end

    message.update!(source_id: response.dig('data', 'message_id')) if response&.dig('data', 'message_id')
  end

  def message_params
    {
      phone_number: contact_inbox.source_id,
      message: message.content,
      image_url: attachments.first
    }
  end

  def attachments
    message.attachments.map(&:download_url)
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end
end