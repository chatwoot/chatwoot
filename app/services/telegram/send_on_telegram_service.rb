class Telegram::SendOnTelegramService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Telegram
  end

  def perform_reply
    ## send reply to telegram message api
    # https://core.telegram.org/bots/api#sendmessage
    message_id = channel.send_message_on_telegram(message)
    message.update!(source_id: message_id) if message_id.present?
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end
end
