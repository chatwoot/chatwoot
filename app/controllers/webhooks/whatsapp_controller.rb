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
    # For Facebook WhatsApp Business API webhook verification, use FB_VERIFY_TOKEN
    fb_verify_token = ENV.fetch('FB_VERIFY_TOKEN', nil)
    return token == fb_verify_token if fb_verify_token.present?

    # Fallback to channel-specific verification for backward compatibility
    # Try to find channel by phone_number_id first (new format), then by phone_number (old format)
    phone_number_id = extract_phone_number_id_from_payload

    channel = if phone_number_id.present?
                find_channel_by_phone_number_id(phone_number_id)
              else
                Channel::Whatsapp.find_by(phone_number: params[:phone_number])
              end

    whatsapp_webhook_verify_token = channel.provider_config['webhook_verify_token'] if channel.present?
    token == whatsapp_webhook_verify_token if whatsapp_webhook_verify_token.present?
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
