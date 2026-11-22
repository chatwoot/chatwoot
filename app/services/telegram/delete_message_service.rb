# Deletes an outgoing message for the customer on Telegram before Chatwoot soft-deletes it.
# Raises CustomExceptions::ChannelMessageDeleteFailed when Telegram refuses or the message is past Telegram's 48 hour limit,
# so the message is kept in Chatwoot too.

# ref: https://core.telegram.org/bots/api#deletemessages
# ref: https://core.telegram.org/bots/api#deletebusinessmessages
class Telegram::DeleteMessageService
  # created_at is set before the message reaches telegram, the margin avoids hitting telegram's limit at the edge
  DELETE_WINDOW = 48.hours - 5.minutes
  # telegram deletes at most 100 messages per request, retries of a partly sent message can save more ids than that
  DELETE_BATCH_SIZE = 100

  pattr_initialize [:message!]

  def perform
    return unless on_telegram?

    raise_failed(I18n.t('errors.messages.telegram_delete.expired')) if message.created_at <= DELETE_WINDOW.ago

    # every batch has to succeed, otherwise the message is kept in Chatwoot. Telegram skips ids already deleted, so trying again is safe
    telegram_message_ids.each_slice(DELETE_BATCH_SIZE) do |message_ids|
      response = request_deletion(message_ids)
      next if response.success? && response.parsed_response['ok'] == true

      raise_failed(I18n.t('errors.messages.telegram_delete.failed', reason: response.parsed_response['description']))
    end
  end

  private

  # ids are saved as each part reaches telegram, while source_id is only set once the whole send finished (and cleared on retry)
  def on_telegram?
    message.outgoing? && !message.private? && !message.deleted && telegram_message_ids.present?
  end

  def raise_failed(error_message)
    raise CustomExceptions::ChannelMessageDeleteFailed.new(message: error_message)
  end

  # Messages sent before all ids were recorded, and messages typed in the business account's own app, only have the source_id
  def telegram_message_ids
    @telegram_message_ids ||= message.external_source_ids['telegram_message_ids'].presence || Array(message.source_id.presence&.to_i)
  end

  def request_deletion(message_ids)
    business_connection_id = channel.business_connection_id(message)

    if business_connection_id.present?
      HTTParty.post("#{channel.telegram_api_url}/deleteBusinessMessages",
                    body: { business_connection_id: business_connection_id, message_ids: message_ids.to_json })
    else
      HTTParty.post("#{channel.telegram_api_url}/deleteMessages", body: { chat_id: channel.chat_id(message), message_ids: message_ids.to_json })
    end
  end

  def channel
    @channel ||= message.inbox.channel
  end
end
