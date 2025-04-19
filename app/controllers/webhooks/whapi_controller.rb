class Webhooks::WhapiController < ActionController::API
  # Remove the before_action that checks for signature verification
  # before_action :verify_webhook_signature, if: :verify_signature?
  
  def callback
    # Find the channel for logging purposes
    channel = find_channel_by_whapi_id || find_channel_by_phone_number
    
    if channel.blank?
      channel_id = params[:channel_id] || params.dig(:whapi, :channel_id)
      phone_number = extract_phone_number_from_params
      Rails.logger.error("WHAPI webhook: No channel found. Channel ID: #{channel_id}, Extracted phone: #{phone_number}")
      return head :unauthorized 
    end
    
    process_webhook
    head :ok
  end
  
  private
  
  def process_webhook
    # Check for specific message types to log more details
    if voice_message_in_payload?
      Rails.logger.info("WHAPI Voice message detected in webhook payload")
      log_voice_message_details
    end
    
    # Log the webhook payload for debugging
    Rails.logger.info("WHAPI Webhook Payload: #{permitted_params.to_h}")
    
    # Queue the job to process this webhook
    Webhooks::WhatsappEventsJob.perform_later(permitted_params.to_h.deep_symbolize_keys)
  end
  
  # Detect if there's a voice message in the webhook payload
  def voice_message_in_payload?
    message = params.dig(:messages, 0)
    return false if message.blank?
    
    message[:type] == 'voice' || 
    message.dig(:voice).present? ||
    (message[:type] == 'audio' && message.dig(:audio, :is_voice) == true)
  end
  
  # Log detailed information about voice messages for debugging
  def log_voice_message_details
    message = params.dig(:messages, 0)
    return if message.blank?
    
    voice_data = message[:voice] || message[:audio]
    
    Rails.logger.info("WHAPI Voice Message Details:")
    Rails.logger.info("- Message ID: #{message[:id]}")
    Rails.logger.info("- Message Type: #{message[:type]}")
    Rails.logger.info("- Voice Data: #{voice_data.inspect}") if voice_data.present?
    
    # Check for expected URL fields
    url = voice_data[:url] || voice_data[:link] if voice_data.present?
    Rails.logger.info("- Voice URL: #{url}")
    
    # Check for MIME type information
    mime_type = voice_data[:mime_type] || voice_data[:mimetype] if voice_data.present?
    Rails.logger.info("- MIME Type: #{mime_type}")
  end
  
  # The signature verification methods are kept but no longer used
  # They're here for reference in case signature verification is added in the future
  
  def verify_webhook_signature
    provided_signature = request.headers['X-Whapi-Signature'] || ''
    
    # Try to find channel by channel_id first, then fall back to phone number
    channel = find_channel_by_whapi_id || find_channel_by_phone_number
    
    if channel.blank?
      channel_id = params[:channel_id] || params.dig(:whapi, :channel_id)
      phone_number = extract_phone_number_from_params
      Rails.logger.error("WHAPI webhook: No channel found. Channel ID: #{channel_id}, Extracted phone: #{phone_number}")
      return head :unauthorized 
    end
    
    # Compute expected signature
    webhook_secret = channel.provider_config['webhook_secret'] || ''
    
    if webhook_secret.blank?
      Rails.logger.error("WHAPI webhook: No webhook_secret configured for channel #{channel.id}")
      return head :unauthorized
    end
    
    computed_signature = OpenSSL::HMAC.hexdigest('SHA256', webhook_secret, request.raw_post)
    
    # Compare signatures
    unless ActiveSupport::SecurityUtils.secure_compare(provided_signature, computed_signature)
      Rails.logger.error("WHAPI webhook: Signature verification failed")
      Rails.logger.error("WHAPI webhook: Provided signature: #{provided_signature}")
      Rails.logger.error("WHAPI webhook: Computed signature: #{computed_signature}")
      head :unauthorized
    end
  end
  
  # Find channel by WHAPI channel_id
  def find_channel_by_whapi_id
    channel_id = params[:channel_id] || params.dig(:whapi, :channel_id)
    return nil if channel_id.blank?
    
    # Look for WHAPI channels where channel_id is stored in provider_config
    Channel::Whatsapp.where(provider: 'whapi').each do |channel|
      return channel if channel.provider_config['channel_id'] == channel_id
    end
    
    nil
  end
  
  # Find channel by phone number (fallback method)
  def find_channel_by_phone_number
    phone_number = extract_phone_number_from_params
    return nil if phone_number.blank?
    
    # First try to find an exact match
    channel = Channel::Whatsapp.find_by(phone_number: phone_number, provider: 'whapi')
    return channel if channel.present?
    
    # If no exact match, try all WHAPI channels - maybe the number format is different
    Channel::Whatsapp.where(provider: 'whapi').each do |channel|
      # Normalize both numbers (remove +, spaces, etc.) and compare
      normalized_channel = channel.phone_number.gsub(/[^0-9]/, '')
      normalized_param = phone_number.gsub(/[^0-9]/, '')
      
      return channel if normalized_channel == normalized_param
    end
    
    nil
  end
  
  def extract_phone_number_from_params
    # Try multiple locations where phone number might be found in WHAPI webhook payload
    phone_number = params[:phone_number] || 
                   params[:receiver] || 
                   params.dig(:messages, 0, :chat_id)&.split('@')&.first || 
                   params.dig(:contacts, 0, :wa_id) ||
                   params.dig(:status, :to)
    
    # Ensure phone number is in E.164 format (with '+' prefix)
    return phone_number if phone_number.blank? || phone_number.start_with?('+')
    
    "+#{phone_number}"
  end
  
  def verify_signature?
    # Since WHAPI doesn't use signature verification, we return false
    false
  end
  
  def permitted_params
    params.permit!
  end
end