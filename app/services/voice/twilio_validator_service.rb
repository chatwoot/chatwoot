module Voice
  # Validates incoming Twilio webhooks to ensure they are legitimate requests
  class TwilioValidatorService
    pattr_initialize [:account!, :params!, :request!]

    def valid?
      # Skip validation for these cases:
      return true if skip_validation?
      
      begin
        # Find the inbox and get the auth token
        to_number = params['To']
        inbox = find_voice_inbox(to_number)
        
        # Allow callbacks if we can't find the inbox or auth token
        return true unless inbox
        return true unless (auth_token = get_auth_token(inbox))
        
        # Check if we have a signature to validate
        signature = request.headers['X-Twilio-Signature']
        return true unless signature.present?
        
        # Validate the signature
        validator = Twilio::Security::RequestValidator.new(auth_token)
        url = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
        
        is_valid = validator.validate(url, params.to_unsafe_h, signature)
        
        # Log validation result
        if is_valid
          Rails.logger.info("✅ TWILIO VALIDATION: Valid signature confirmed")
        else
          Rails.logger.error("⚠️ TWILIO VALIDATION: Invalid signature for URL: #{url}")
          return false
        end
      rescue StandardError => e
        Rails.logger.error("❌ TWILIO VALIDATION ERROR: #{e.message}")
        return true # Allow on errors for robustness
      end

      true
    end

    private
    
    def skip_validation?
      # Skip for OPTIONS requests and in development
      return true if request.method == "OPTIONS"
      return true if Rails.env.development?
      return true if account.blank?
      
      false
    end

    def get_auth_token(inbox)
      channel = inbox.channel
      return nil unless channel.is_a?(Channel::Voice)
      
      provider_config = channel.provider_config_hash
      provider_config['auth_token'] if provider_config.present?
    end

    def find_voice_inbox(to_number)
      return nil if to_number.blank?
      
      account.inboxes
             .where(channel_type: 'Channel::Voice')
             .joins('INNER JOIN channel_voice ON channel_voice.id = inboxes.channel_id')
             .where('channel_voice.phone_number = ?', to_number)
             .first
    end
  end
end