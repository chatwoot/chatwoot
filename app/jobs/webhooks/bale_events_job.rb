class Webhooks::BaleEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    return unless params[:bot_token]

    channel = Channel::Bale.find_by(bot_token: params[:bot_token])

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
    Rails.logger.warn("Bale event discarded: #{message}")
  end

  def process_event_params(channel, params)
    return unless params[:bale]

    if params.dig(:bale, :edited_message).present?
      Bale::UpdateMessageService.new(inbox: channel.inbox, params: params['bale'].with_indifferent_access).perform
    else
      Bale::IncomingMessageService.new(inbox: channel.inbox, params: params['bale'].with_indifferent_access).perform
    end
  end
end
