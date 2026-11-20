# Deletes an outgoing message for the customer on Telegram before Chatwoot soft-deletes it.
# Telegram only allows this within 48 hours of sending, older messages are only deleted in Chatwoot.
# Raises CustomExceptions::ChannelMessageDeleteFailed when Telegram refuses, so the message is kept in Chatwoot too.

# ref: https://core.telegram.org/bots/api#deletemessages
# ref: https://core.telegram.org/bots/api#deletebusinessmessages
class Telegram::DeleteMessageService
  # created_at is set before the message reaches telegram, the margin avoids hitting telegram's limit at the edge
  DELETE_WINDOW = 48.hours - 5.minutes

  pattr_initialize [:message!]

  def perform
    return unless deletable_on_telegram?

    response = request_deletion
    return if response.success? && response.parsed_response['ok'] == true

    raise CustomExceptions::ChannelMessageDeleteFailed.new(
      message: I18n.t('errors.messages.telegram_delete.failed', reason: response.parsed_response['description'])
    )
  end

  private

  # source_id is set once anything was delivered to telegram
  def deletable_on_telegram?
    message.outgoing? && !message.private? && !message.deleted && message.source_id.present? && message.created_at > DELETE_WINDOW.ago
  end

  # Messages sent before all ids were recorded, and messages typed in the business account's own app, only have the source_id
  def telegram_message_ids
    message.external_source_ids['telegram_message_ids'].presence || [message.source_id.to_i]
  end

  def request_deletion
    business_connection_id = channel.business_connection_id(message)

    if business_connection_id.present?
      HTTParty.post("#{channel.telegram_api_url}/deleteBusinessMessages",
                    body: { business_connection_id: business_connection_id, message_ids: telegram_message_ids.to_json })
    else
      HTTParty.post("#{channel.telegram_api_url}/deleteMessages",
                    body: { chat_id: channel.chat_id(message), message_ids: telegram_message_ids.to_json })
    end
  end

  def channel
    @channel ||= message.inbox.channel
  end
end
