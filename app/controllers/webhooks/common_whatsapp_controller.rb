class Webhooks::CommonWhatsappController < ActionController::API

  def process_payload
    return if params[:event] != 'onmessage'
    Webhooks::CommonWhatsappEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  private

  def valid_token?(token)
    # Rails.logger.info("VALID TOKEN?")
    channel = Channel::CommonWhatsapp.find_by(phone_number: params[:phone_number])
    # Rails.logger.info(channel)
    whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token'] if channel.present?
    # Rails.logger.info(whatsapp_webhook_verify_token)
    # Rails.logger.info(token == whatsapp_webhook_verify_token)
    token == whatsapp_webhook_verify_token if whatsapp_webhook_verify_token.present?
  end
end
