class Webhooks::TelegramEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    return unless params[:bot_token]

    channel = Channel::Telegram.find_by(bot_token: params[:bot_token])

    if channel_is_inactive?(channel)
      log_inactive_channel(channel, params)
      return
    end

    process_event_params(channel, params)
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
    telegram_params = params[:telegram].presence || params.except(:bot_token, :controller, :action).presence
    return if telegram_params.blank?

    telegram_params = telegram_params.with_indifferent_access
    if telegram_params[:edited_message].present? || telegram_params[:edited_business_message].present?
      Telegram::UpdateMessageService.new(inbox: channel.inbox, params: telegram_params).perform
    else
      Telegram::IncomingMessageService.new(inbox: channel.inbox, params: telegram_params).perform
    end
  end
end
