class Telegram::SendOnTelegramService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Telegram
  end

  def perform_reply
    ## send reply to telegram message api
    # https://core.telegram.org/bots/api#sendmessage
    # every id is already saved by the channel as it is sent, source_id stays a single id for reply and edit lookups.
    # It is only set once the whole send is done, as a message with a source_id is never sent again on retry.
    message_ids = channel.send_message_on_telegram(message)
    message.update!(source_id: message_ids.first) if message_ids.present?
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end
end
