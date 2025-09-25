class Webhooks::WahaEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    return if params[:isGroup] == true
    return if params[:isFromMe] == true

    channel = Channel::WhatsappUnofficial.find_by(phone_number: params[:phone_number])
    return unless channel

    process_event_params(channel, params)
  end

  private

  def process_event_params(channel, params)
    Waha::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
  end
end
