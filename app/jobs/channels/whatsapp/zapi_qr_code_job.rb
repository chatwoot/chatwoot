class Channels::Whatsapp::ZapiQrCodeJob < ApplicationJob
  queue_as :default

  def perform(whatsapp_channel, attempt = 1)
    return if attempt == 1 && whatsapp_channel.provider_connection.present? && whatsapp_channel.provider_connection['connection'] != 'close'
    return if attempt > 1 && whatsapp_channel.provider_connection['connection'] != 'connecting'

    if attempt > 3
      whatsapp_channel.update_provider_connection!(connection: 'close')
      return
    end

    fetch_and_update_qr_code(whatsapp_channel)
    self.class.set(wait: 30.seconds).perform_later(whatsapp_channel, attempt + 1)
  end

  private

  def fetch_and_update_qr_code(whatsapp_channel)
    service = Whatsapp::Providers::WhatsappZapiService.new(whatsapp_channel: whatsapp_channel)
    qr_code = service.qr_code_image

    return if qr_code.blank?
    # NOTE: Avoid race condition.
    return if whatsapp_channel.reload.provider_connection['connection'] == 'open'

    whatsapp_channel.update_provider_connection!(
      connection: 'connecting',
      qr_data_url: qr_code
    )
  end
end
