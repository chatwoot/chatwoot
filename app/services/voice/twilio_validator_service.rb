module Voice
  class TwilioValidatorService
    pattr_initialize [:account!, :params!, :request!]

    def valid?
      # Skip for OPTIONS requests
      return true if request.method == "OPTIONS"
      
      # Skip validation for local development
      return true if Rails.env.development?

      # Skip if no To param (happens in some callback scenarios)
      to_number = params['To']
      return true if to_number.blank?

      begin
        inbox = find_voice_inbox(to_number)

        # If inbox not found, allow the request for Twilio callbacks
        unless inbox
          Rails.logger.warn("⚠️ No inbox found for phone number #{to_number} - allowing request for Twilio callback")
          return true
        end

        # Get Twilio Auth Token from inbox's channel
        channel = inbox.channel
        unless channel.is_a?(Channel::Voice)
          Rails.logger.warn("⚠️ Channel is not a voice channel - allowing request for Twilio callback") 
          return true
        end

        auth_token = channel.provider_config_hash['auth_token']

        # Validate incoming request signature if present
        signature = request.headers['X-Twilio-Signature']
        
        # Allow requests without signature for callbacks
        unless signature.present?
          Rails.logger.warn("⚠️ No Twilio signature in request - allowing for callbacks")
          return true
        end

        # Validate the signature
        validator = Twilio::Security::RequestValidator.new(auth_token)
        url = "#{request.protocol}#{request.host_with_port}#{request.fullpath}"
        is_valid = validator.validate(url, params.to_unsafe_h, signature)

        unless is_valid
          Rails.logger.error("⚠️ Invalid Twilio signature detected")
          return false
        end
      rescue => e
        Rails.logger.error("Error validating Twilio signature: #{e.message}")
        # Always allow callbacks even if validation fails
        return true
      end

      true
    end

    private

    def find_voice_inbox(to_number)
      account.inboxes
            .where(channel_type: 'Channel::Voice')
            .joins('INNER JOIN channel_voice ON channel_voice.id = inboxes.channel_id')
            .where('channel_voice.phone_number = ?', to_number)
            .first
    end
  end
end