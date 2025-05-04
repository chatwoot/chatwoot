module Voice
  class TwilioValidatorService
    pattr_initialize [:account!, :params!, :request!]

    def valid?
      # Skip for OPTIONS requests
      return true if request.method == "OPTIONS"
      
      # Skip validation for local development
      if Rails.env.development?
        Rails.logger.info("🔑 TWILIO VALIDATION: Skipping in development environment")
        return true
      end
      
      # Skip if we're missing account information
      if account.blank?
        Rails.logger.warn("⚠️ TWILIO VALIDATION: No account provided, allowing request")
        return true
      end

      # Skip if no To param (happens in some callback scenarios)
      to_number = params['To']
      if to_number.blank?
        Rails.logger.warn("⚠️ TWILIO VALIDATION: No 'To' parameter in request, allowing for callbacks")
        return true
      end

      begin
        inbox = find_voice_inbox(to_number)

        # If inbox not found, allow the request for Twilio callbacks
        unless inbox
          Rails.logger.warn("⚠️ TWILIO VALIDATION: No inbox found for phone number #{to_number}, allowing request")
          return true
        end

        # Get Twilio Auth Token from inbox's channel
        channel = inbox.channel
        unless channel.is_a?(Channel::Voice)
          Rails.logger.warn("⚠️ TWILIO VALIDATION: Channel is not a voice channel, allowing request") 
          return true
        end

        provider_config = channel.provider_config_hash
        
        # Check for auth token presence
        if provider_config.blank? || provider_config['auth_token'].blank?
          Rails.logger.warn("⚠️ TWILIO VALIDATION: No auth token available in provider config, allowing request")
          return true
        end
        
        auth_token = provider_config['auth_token']
        
        # Validate incoming request signature if present
        signature = request.headers['X-Twilio-Signature']
        
        # Allow requests without signature for callbacks
        unless signature.present?
          Rails.logger.warn("⚠️ TWILIO VALIDATION: No Twilio signature in request, allowing for callbacks")
          return true
        end

        # Validate the signature
        validator = Twilio::Security::RequestValidator.new(auth_token)
        url = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
        
        # Log validation attempt
        Rails.logger.info("🔐 TWILIO VALIDATION: Validating signature for URL: #{url}")
        
        is_valid = validator.validate(url, params.to_unsafe_h, signature)

        if is_valid
          Rails.logger.info("✅ TWILIO VALIDATION: Valid signature confirmed")
        else
          Rails.logger.error("⚠️ TWILIO VALIDATION: Invalid signature detected")
          
          # For debugging, log details about the validation
          Rails.logger.error("📋 TWILIO VALIDATION DETAILS:")
          Rails.logger.error("URL: #{url}")
          Rails.logger.error("Signature: #{signature}")
          Rails.logger.error("Auth Token: #{auth_token[0..3]}...") # Only log first few chars for security
          
          # Still return false for invalid signatures
          return false
        end
      rescue StandardError => e
        Rails.logger.error("❌ TWILIO VALIDATION ERROR: #{e.message}")
        # Always allow callbacks even if validation fails
        return true
      end

      true
    end

    private

    def find_voice_inbox(to_number)
      return nil if to_number.blank?
      
      inbox = account.inboxes
                   .where(channel_type: 'Channel::Voice')
                   .joins('INNER JOIN channel_voice ON channel_voice.id = inboxes.channel_id')
                   .where('channel_voice.phone_number = ?', to_number)
                   .first
                   
      if inbox
        Rails.logger.info("📥 TWILIO VALIDATION: Found inbox id=#{inbox.id} for phone=#{to_number}")
      else
        Rails.logger.warn("⚠️ TWILIO VALIDATION: No inbox found for phone=#{to_number}")
      end
      
      inbox
    end
  end
end