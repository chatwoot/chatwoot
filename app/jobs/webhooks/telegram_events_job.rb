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
    telegram_params = params[:telegram] || params['telegram']
    return unless telegram_params

    telegram_params = telegram_params.with_indifferent_access
    business_connection_service = Telegram::BusinessConnectionService.new(channel: channel)
    begin
      if telegram_params[:business_connection].present?
        business_connection_service.process(
          telegram_params[:business_connection], update_id: telegram_params[:update_id]
        )
      elsif telegram_params[:edited_message].present? || telegram_params[:edited_business_message].present?
        Telegram::UpdateMessageService.new(inbox: channel.inbox, params: telegram_params).perform
      else
        sync_business_connection(business_connection_service, telegram_params)
        Telegram::IncomingMessageService.new(inbox: channel.inbox, params: telegram_params).perform
      end
    ensure
      observe_update(business_connection_service, telegram_params[:update_id], channel.id)
    end
  end

  def observe_update(business_connection_service, update_id, channel_id)
    business_connection_service.observe_update(update_id)
  rescue StandardError => e
    Rails.logger.error("Failed to record Telegram update ID for channel #{channel_id}: #{e.message}")
  end

  def sync_business_connection(business_connection_service, telegram_params)
    connection_id = telegram_params.dig(:business_message, :business_connection_id)
    business_connection_service.sync(connection_id, update_id: telegram_params[:update_id]) if connection_id.present?
  end
end
