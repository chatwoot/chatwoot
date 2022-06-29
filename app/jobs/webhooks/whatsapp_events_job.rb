class Webhooks::WhatsappEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    channel = find_channel(params)
    return if channel.blank?

    case channel.provider
    when 'whatsapp_cloud'
      Whatsapp::IncomingMessageWhatsappCloudService.new(channel: channel, params: params).perform
    else
      Whatsapp::IncomingMessageWhatsappService.new(channel: channel, params: params).perform
    end
  end

  private

  def find_channel(params)
    return unless params[:phone_number]

    Channel::Whatsapp.find_by(phone_number: params[:phone_number])
  end
end
