class Webhooks::WhatsappEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    return unless params[:phone_number]

    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    return unless channel

    # TODO: pass to appropriate provider service from here
    Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params['whatsapp'].with_indifferent_access).perform
  end
end
