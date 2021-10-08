class Webhooks::TelegramEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    return unless params[:bot_token]

    channel = Channel::Telegram.find_by(bot_token: params[:bot_token])
    return unless channel

    Telegram::IncomingMessageService.new(inbox: channel.inbox, params: params['telegram'].with_indifferent_access).perform
  end
end
