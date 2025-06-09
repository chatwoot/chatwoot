class Fonnte::SendOnFonnteService < Base::SendOnChannelService
  private

  def channel_class
    Channel::WhatsappUnofficial
  end

  def perform_reply

    begin
      fonnte_message = channel.send_message(**message_params)
    rescue ::WhatsappUnofficial::Error => e
      message.update!(status: :failed, external_error: e.message)
    end
    message.update!(source_id: fonnte_message['id']) if fonnte_message
  end

  def message_params
    {
      to: contact_inbox.source_id,
      message: message.content,
      url: attachments
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

  def outgoing_message?
    message.outgoing? || message.template?
  end
end
