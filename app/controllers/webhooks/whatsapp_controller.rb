class Webhooks::WhatsappController < ActionController::API
  include MetaTokenVerifyConcern

  def process_payload
    Rails.logger.info "[WHATSAPP_DEBUG] 🌐 Webhook received: #{params.inspect}"

    # Extract phone_number_id from Facebook WhatsApp Business API payload or use URL param for backward compatibility
    phone_number_id = extract_phone_number_id_from_payload
    phone_number = params[:phone_number] # For backward compatibility with old webhook format

    Rails.logger.info "[WHATSAPP_DEBUG] 📱 Phone Number ID: #{phone_number_id}, Phone Number: #{phone_number}"

    if inactive_whatsapp_number?(phone_number)
      Rails.logger.warn("Rejected webhook for inactive WhatsApp number: #{phone_number}")
      render json: { error: 'Inactive WhatsApp number' }, status: :unprocessable_entity
      return
    end

    # Add phone_number_id to params for processing
    enhanced_params = params.to_unsafe_hash
    enhanced_params[:phone_number_id] = phone_number_id if phone_number_id.present?

    Rails.logger.info "[WHATSAPP_DEBUG] 📤 Enqueuing WhatsAppEventsJob with phone_number_id: #{phone_number_id}"
    Webhooks::WhatsappEventsJob.perform_later(enhanced_params)
    head :ok
  end

  private

  def valid_token?(token)
    # For webhook verification, we need to check if the token matches any WhatsApp channel
    # or account-level settings since Facebook doesn't send phone_number_id during verification

    # First, try to find channel by phone_number if provided in URL (backward compatibility)
    if params[:phone_number].present?
      channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
      if channel.present?
        whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token']
        return token == whatsapp_webhook_verify_token if whatsapp_webhook_verify_token.present?
      end
    end

    # Check account-level WhatsApp settings (for multi-tenant setup)
    if defined?(AccountWhatsappSettings)
      AccountWhatsappSettings.find_each do |settings|
        return true if settings.verify_token.present? && token == settings.verify_token
      end
    end

    # For unified endpoint, check all WhatsApp channels to find matching token
    # This is necessary during webhook verification when we don't have phone_number_id yet
    Channel::Whatsapp.where(provider: 'whatsapp_cloud').find_each do |whatsapp_channel|
      webhook_token = whatsapp_channel.provider_config['webhook_verify_token']
      return true if webhook_token.present? && token == webhook_token
    end

    false
  end

  def inactive_whatsapp_number?(phone_number = nil)
    phone_number ||= params[:phone_number]
    return false if phone_number.blank?

    inactive_numbers = GlobalConfig.get_value('INACTIVE_WHATSAPP_NUMBERS').to_s
    return false if inactive_numbers.blank?

    inactive_numbers_array = inactive_numbers.split(',').map(&:strip)
    inactive_numbers_array.include?(phone_number)
  end

  # Extract phone_number_id from Facebook WhatsApp Business API webhook payload
  def extract_phone_number_id_from_payload
    return nil unless params[:object] == 'whatsapp_business_account'
    return nil if params[:entry].blank?

    # Navigate through the Facebook webhook payload structure
    entry = params[:entry].first
    return nil if entry[:changes].blank?

    change = entry[:changes].first
    return nil unless change[:field] == 'messages'

    metadata = change.dig(:value, :metadata)
    metadata&.dig(:phone_number_id)
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP_DEBUG] Error extracting phone_number_id: #{e.message}"
    nil
  end

  # Find WhatsApp channel by phone_number_id in provider_config
  def find_channel_by_phone_number_id(phone_number_id)
    Channel::Whatsapp.find_by("provider_config->>'phone_number_id' = ?", phone_number_id)
  end
end
