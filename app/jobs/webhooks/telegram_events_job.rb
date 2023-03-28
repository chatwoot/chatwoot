class Webhooks::TelegramEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    return unless params[:bot_token]

    channel = Channel::Telegram.find_by(bot_token: params[:bot_token])
    return unless channel

    if params['telegram']['callback_query'].present?
      param = params['telegram']['callback_query']
      params['telegram']['callback_query']['message']['text'] = params['telegram']['callback_query']['data']
      params['telegram']['callback_query']['message']['username'] = params['telegram']['callback_query']['from']['username']
      params['telegram']['callback_query']['message']['from']['id'] = params['telegram']['callback_query']['from']['id']

    else
      param = params['telegram']
    end
    Telegram::IncomingMessageService.new(inbox: channel.inbox, params: param.with_indifferent_access).perform
  end
end
