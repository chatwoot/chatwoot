class Webhooks::WhatsappEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    return unless params[:phone_number]

    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    return unless channel


    if channel.provider == 'whatsapp_cloud'
      Whatsapp::IncomingMessageWhatsappCloudService.new(inbox: channel.inbox, params: params['whatsapp'].with_indifferent_access).perform
    else
      Whatsapp::IncomingMessageService.new(inbox: channel.inbox, params: params['whatsapp'].with_indifferent_access).perform
    end
  end
end
