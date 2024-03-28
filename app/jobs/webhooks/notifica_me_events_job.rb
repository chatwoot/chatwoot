class Webhooks::NotificaEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    return unless params[:channel_token]

    channel = Channel::Notification.find_by(channel_token: params[:channel_token])
    return unless channel

    process_event_params(channel, params)
  end

  private

  def process_event_params(channel, params)
    return unless params[:telegram]

    # if params.dig(:telegram, :edited_message).present?
    #   Telegram::UpdateMessageService.new(inbox: channel.inbox, params: params['telegram'].with_indifferent_access).perform
    # else
    #   Telegram::IncomingMessageService.new(inbox: channel.inbox, params: params['telegram'].with_indifferent_access).perform
    # end
  end
end
