class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  before_action :validate_whapi_signature, only: [:process_payload]

  def process_payload
    correlation_id = request.request_id || SecureRandom.uuid
    if inactive_whatsapp_number?
      # Preserve existing log message format for specs/backward compatibility
      Rails.logger.warn("Rejected webhook for inactive WhatsApp number: #{params[:phone_number]}")
      render json: { error: 'Inactive WhatsApp number', correlation_id: correlation_id }, status: :unprocessable_entity
      return
    end

    ActiveSupport::Notifications.instrument('whapi.webhook', action: 'received', correlation_id: correlation_id, has_phone_number: params[:phone_number].present?)
    payload = params.to_unsafe_hash.merge('correlation_id' => correlation_id)
    Webhooks::WhatsappEventsJob.perform_later(payload)
    render json: { status: 'accepted', correlation_id: correlation_id }
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

  # Validate WHAPI webhook signature if request is for /webhooks/whapi
  # Optional: enabled only when a secret is configured
  def validate_whapi_signature
    # Only validate for partner endpoint which does not include :phone_number in the path
    return if params[:phone_number].present?

    secret = ENV['WHAPI_PARTNER_WEBHOOK_SECRET'].presence || ENV['WHAPI_PARTNER_TOKEN'].presence
    return if secret.blank?

    signature_header = request.headers['X-Whapi-Signature'].presence || request.headers['Whapi-Signature'].presence || request.headers['X-Signature'].presence
    unless signature_header
      Rails.logger.warn('[WhapiWebhook] Missing signature header')
      render json: { message: 'signature missing' }, status: :unauthorized and return
    end

    payload = request.raw_post.to_s
    computed_hex = OpenSSL::HMAC.hexdigest('sha256', secret, payload)
    computed_b64 = Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', secret, payload))

    provided = signature_header.to_s.strip
    valid = secure_compare(provided, computed_hex) || secure_compare(provided, computed_b64)

    unless valid
      Rails.logger.warn('[WhapiWebhook] Invalid signature')
      render json: { message: 'invalid signature' }, status: :unauthorized and return
    end
  end

  def secure_compare(a, b)
    return false if a.blank? || b.blank?
    ActiveSupport::SecurityUtils.secure_compare(a, b) rescue false
  end
end
