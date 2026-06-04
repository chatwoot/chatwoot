class Channels::Whatsapp::ZapiReadMessageJob < ApplicationJob
  queue_as :default

  def perform(whatsapp_channel, phone, message_source_id)
    service = Whatsapp::Providers::WhatsappZapiService.new(whatsapp_channel: whatsapp_channel)
    service.send_read_message(phone, message_source_id)
  end
end
