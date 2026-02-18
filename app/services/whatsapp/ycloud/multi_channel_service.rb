# YCloud multi-channel messaging: SMS, Email, Voice, and Verification.
# Enables fallback channels and OTP verification beyond WhatsApp.
# https://docs.ycloud.com/reference/introduction
module Whatsapp::Ycloud
  class MultiChannelService
    pattr_initialize [:whatsapp_channel!]

    # --- SMS ---

    # Send an SMS message.
    # @param params [Hash]:
    #   - to [String] Recipient phone number (E.164)
    #   - text [String] SMS body
    #   - from [String] (optional) Sender ID
    def send_sms(params)
      client.post('/sms/send', params)
    end

    # List SMS records.
    # @param page [Integer] Page number
    # @param limit [Integer] Items per page
    def list_sms(page: 1, limit: 20)
      client.get('/sms', page: page, limit: limit)
    end

    # --- Email ---

    # Send an email.
    # @param params [Hash]:
    #   - from [String] Sender email
    #   - to [String] Recipient email
    #   - subject [String] Email subject
    #   - contentType [String] 'text/plain' or 'text/html'
    #   - content [String] Email body
    def send_email(params)
      client.post('/emails/send', params)
    end

    # --- Voice ---

    # Send a voice message (automated call with TTS or audio).
    # @param params [Hash]:
    #   - to [String] Recipient phone number (E.164)
    #   - verificationCode [String] Code to speak
    #   - language [String] Language code
    def send_voice(params)
      client.post('/voice/send', params)
    end

    # List voice records.
    def list_voice(page: 1, limit: 20)
      client.get('/voice', page: page, limit: limit)
    end

    # --- Verification (OTP) ---

    # Start a verification (sends code via best channel: WhatsApp > SMS > Voice).
    # @param params [Hash]:
    #   - channel [String] 'whatsapp' | 'sms' | 'voice' | 'email_code' | 'auto'
    #   - to [String] Phone number or email
    #   - codeLength [Integer] (optional) 4-8, defaults to 6
    #   - locale [String] (optional) Language for message
    #   - senderId [String] (optional) SMS sender ID
    def send_verification(params)
      client.post('/verify/verificationChecks', params)
    end

    # Start verification request.
    def start_verification(params)
      client.post('/verify/verifications', params)
    end

    # Check a verification code.
    # @param params [Hash]:
    #   - verificationId [String] ID from start_verification response
    #   - code [String] Code entered by user
    def check_verification(params)
      client.post('/verify/verificationChecks', params)
    end

    private

    def client
      @client ||= ApiClient.new(whatsapp_channel: whatsapp_channel)
    end
  end
end
