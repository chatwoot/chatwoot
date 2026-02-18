class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  def process_payload
    if inactive_whatsapp_number?
      Rails.logger.warn("Rejected webhook for inactive WhatsApp number: #{params[:phone_number]}")
      render json: { error: 'Inactive WhatsApp number' }, status: :unprocessable_entity
      return
    end

    # Verify YCloud webhook signature (HMAC-SHA256) if the channel uses YCloud and has a webhook secret
    if ycloud_channel? && !verify_ycloud_signature
      Rails.logger.warn("YCloud webhook signature verification failed for #{params[:phone_number]}")
      head :unauthorized
      return
    end

    Webhooks::WhatsappEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  private

  def valid_token?(token)
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

  def ycloud_channel?
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    channel&.provider == 'ycloud'
  end

  def verify_ycloud_signature
    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
    return true if channel.blank?

    webhook_secret = channel.provider_config['webhook_secret']
    return true if webhook_secret.blank? # Skip verification if no secret configured

    signature_header = request.headers['YCloud-Signature']
    return false if signature_header.blank?

    Whatsapp::Ycloud::ApiClient.verify_signature(request.raw_post, signature_header, webhook_secret)
  end
end
