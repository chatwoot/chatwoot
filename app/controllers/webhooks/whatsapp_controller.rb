class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  # GP_BIKES_DEBUG: Enhanced logging for webhook verification debugging
  def verify
    Rails.logger.info '[WHATSAPP_WEBHOOK] Verification request received'
    Rails.logger.info "[WHATSAPP_WEBHOOK] Phone: #{params[:phone_number]}"
    Rails.logger.info "[WHATSAPP_WEBHOOK] Hub mode: #{params['hub.mode']}"
    Rails.logger.info "[WHATSAPP_WEBHOOK] Hub challenge: #{params['hub.challenge']&.first(20)}..." # Truncate for logs
    Rails.logger.info "[WHATSAPP_WEBHOOK] Hub verify_token received: #{params['hub.verify_token']&.first(10)}..." # Truncate for security

    super # Call MetaTokenVerifyConcern#verify
  end

  def process_payload
    Rails.logger.info "[WHATSAPP_WEBHOOK] Message payload received for: #{params[:phone_number]}"

    if inactive_whatsapp_number?
      Rails.logger.warn("[WHATSAPP_WEBHOOK] Rejected webhook for inactive WhatsApp number: #{params[:phone_number]}")
      render json: { error: 'Inactive WhatsApp number' }, status: :unprocessable_entity
      return
    end

    Webhooks::WhatsappEventsJob.perform_later(params.to_unsafe_hash)
    Rails.logger.info '[WHATSAPP_WEBHOOK] Message queued for processing'
    head :ok
  end

  private

  def valid_token?(token)
    Rails.logger.info "[WHATSAPP_WEBHOOK] Validating token for phone: #{params[:phone_number]}"

    channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])

    if channel.blank?
      Rails.logger.error "[WHATSAPP_WEBHOOK] No channel found for phone: #{params[:phone_number]}"
      return false
    end

    Rails.logger.info "[WHATSAPP_WEBHOOK] Channel found: ID=#{channel.id}, Provider=#{channel.provider}"

    whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token']

    if whatsapp_webhook_verify_token.blank?
      Rails.logger.error "[WHATSAPP_WEBHOOK] webhook_verify_token is blank in provider_config for channel #{channel.id}"
      return false
    end

    Rails.logger.info "[WHATSAPP_WEBHOOK] Stored token (first 10 chars): #{whatsapp_webhook_verify_token[0...10]}..."
    Rails.logger.info "[WHATSAPP_WEBHOOK] Received token (first 10 chars): #{token[0...10]}..."

    tokens_match = token == whatsapp_webhook_verify_token

    if tokens_match
      Rails.logger.info '[WHATSAPP_WEBHOOK] ✅ Token validation SUCCESS'
    else
      Rails.logger.error "[WHATSAPP_WEBHOOK] ❌ Token validation FAILED - tokens don't match"
    end

    tokens_match
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
