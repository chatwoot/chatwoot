class Webhooks::TelegramEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    return unless params[:bot_token]
    return unless params[:telegram]

    channel = Channel::Telegram.find_by(bot_token: params[:bot_token])
    return unless channel

    process_event_params(channel, params)
  end

  private

  def process_event_params(channel, params)
    if params.dig(:telegram, :edited_message).present?
      Telegram::UpdateMessageService.new(inbox: channel.inbox, params: params['telegram'].with_indifferent_access).perform
    else
      Telegram::IncomingMessageService.new(inbox: channel.inbox, params: params['telegram'].with_indifferent_access).perform
    end
  end
end
