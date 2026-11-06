class Telegram::SendOnTelegramService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Telegram
  end

  def perform_reply
    ## send reply to telegram message api
    # https://core.telegram.org/bots/api#sendmessage
    message_ids = channel.send_message_on_telegram(message)
    return if message_ids.blank?

    # source_id stays a single id for reply and edit lookups; all ids are kept so the message can be deleted on telegram.
    # A retry resends the whole message, so ids from earlier partial attempts are kept as well.
    telegram_message_ids = (Array(message.external_source_ids['telegram_message_ids']) + message_ids).uniq
    message.update!(source_id: message_ids.first,
                    external_source_ids: message.external_source_ids.merge('telegram_message_ids' => telegram_message_ids))
  end

  def inbox
    @inbox ||= message.inbox
  end

  def channel
    @channel ||= inbox.channel
  end
end
