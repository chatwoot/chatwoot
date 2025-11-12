class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  def events
    Rails.logger.info('WhatsApp webhook received events')
    if params['object'].casecmp('whatsapp_business_account').zero?
      Webhooks::WhatsappEventsJob.perform_later(params.to_unsafe_hash)
      render json: :ok
    else
      Rails.logger.warn("Message is not received from the WhatsApp webhook event: #{params['object']}")
      head :unprocessable_entity
    end
  end

  def process_payload
    if inactive_whatsapp_number?
      Rails.logger.warn("Rejected webhook for inactive WhatsApp number: #{params[:phone_number]}")
      render json: { error: 'Inactive WhatsApp number' }, status: :unprocessable_entity
      return
    end

    Webhooks::WhatsappEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  private

  def valid_token?(token)
    return token == GlobalConfigService.load('WHATSAPP_VERIFY_TOKEN', '') if params[:phone_number].blank?

    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token'] if channel.present?
    token == whatsapp_webhook_verify_token if whatsapp_webhook_verify_token.present?
  end

  def inactive_whatsapp_number?
    phone_number = params[:phone_number]
    return false if phone_number.blank?

    inactive_numbers = GlobalConfig.get_value('INACTIVE_WHATSAPP_NUMBERS').to_s
    return false if inactive_numbers.blank?

    inactive_numbers_array = inactive_numbers.split(',').map(&:strip)
    inactive_numbers_array.include?(phone_number)
  end
end
