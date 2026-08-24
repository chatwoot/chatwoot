class Bale::SendOnBaleService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Bale
  end

  def perform_reply
    message_id = channel.send_message_on_bale(message)
    message.update!(source_id: message_id) if message_id.present?
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end
end
