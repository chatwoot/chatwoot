class Webhooks::TelegramEventsJob < MutexApplicationJob
  queue_as :default
  # Retry budget (19 × 2s = 38s) must exceed the 30s lock TTL set in `perform`, otherwise
  # an update that arrives just after the lock is acquired can exhaust retries before the
  # holder finishes and silently drop its message.
  retry_on LockAcquisitionError, wait: 2.seconds, attempts: 20

  def perform(params = {})
    return unless params[:bot_token]

    channel = Channel::Telegram.find_by(bot_token: params[:bot_token])

    if channel_is_inactive?(channel)
      log_inactive_channel(channel, params)
      return
    end

    chat_id = params.dig(:telegram, :message, :chat, :id) || params.dig(:telegram, :business_message, :chat, :id)
    return process_event_params(channel, params) if chat_id.blank?

    # Album photos arrive as separate concurrent updates. Serialize per (inbox, chat)
    # so the first update creates the conversation and the rest append to it.
    # 30s TTL covers the attachment download — the default 1s expires mid-processing
    # and lets a concurrent update re-acquire before the first commit.
    key = format(::Redis::Alfred::TELEGRAM_MESSAGE_MUTEX, inbox_id: channel.inbox.id, chat_id: chat_id)
    with_lock(key, 30.seconds) do
      process_event_params(channel, params)
    end
  end

  private

  def channel_is_inactive?(channel)
    return true if channel.blank?
    return true unless channel.account.active?

    false
  end

  def log_inactive_channel(channel, params)
    message = if channel&.id
                "Account #{channel.account.id} is not active for channel #{channel.id}"
              else
                "Channel not found for bot_token: #{params[:bot_token]}"
              end
    Rails.logger.warn("Telegram event discarded: #{message}")
  end

  def process_event_params(channel, params)
    return unless params[:telegram]

    if params.dig(:telegram, :edited_message).present? || params.dig(:telegram, :edited_business_message).present?
      Telegram::UpdateMessageService.new(inbox: channel.inbox, params: params['telegram'].with_indifferent_access).perform
    else
      Telegram::IncomingMessageService.new(inbox: channel.inbox, params: params['telegram'].with_indifferent_access).perform
    end
  end
end
