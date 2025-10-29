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
    # Priority 1: Try global FB_VERIFY_TOKEN (for Facebook WhatsApp Business API)
    fb_verify_token = GlobalConfig.get_value('FB_VERIFY_TOKEN')
    return token == fb_verify_token if fb_verify_token.present?

    # Priority 2: Fallback to channel-specific verification for backward compatibility
    # Try multiple methods to find the channel:
    # 1. By phone_number_id from Facebook payload (new format)
    # 2. By phone_number from URL params (old 360Dialog format)
    channel = find_channel_for_verification

    return false unless channel.present?

    whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token']
    return false unless whatsapp_webhook_verify_token.present?

    token == whatsapp_webhook_verify_token
  end

  def find_channel_for_verification
    # Try phone_number_id first (Facebook WhatsApp Business API)
    phone_number_id = extract_phone_number_id_from_payload
    if phone_number_id.present?
      channel = find_channel_by_phone_number_id(phone_number_id)
      return channel if channel.present?
    end

    # Fallback to phone_number from URL params (360Dialog and old format)
    if params[:phone_number].present?
      channel = Channel::Whatsapp.find_by(phone_number: params[:phone_number])
      return channel if channel.present?
    end

    nil
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
    return nil unless params[:entry].present?

    # Navigate through the Facebook webhook payload structure
    entry = params[:entry].first
    return nil unless entry[:changes].present?

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
    Channel::Whatsapp.find_by_phone_number_id(phone_number_id)
  end
end
