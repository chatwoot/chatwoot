class Webhooks::CommonWhatsappEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    channel = find_channel_by_url_param(params)

    CommonWhatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params).perform

  end

  private

  def find_channel_by_url_param(params)
    return unless params[:session]

    Channel::CommonWhatsapp.find_by(phone_number: params[:session])
  end

end
