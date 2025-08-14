module Voice
  class IncomingCallService
    pattr_initialize [:account!, :params!]

    def process
      find_inbox

      ActiveRecord::Base.transaction do
        find_or_create_conversation
        # Delegate creation of voice message and initial status to the orchestrator
        Voice::CallOrchestratorService.new(
          account: account,
          inbox: @inbox,
          direction: :inbound,
          phone_number: caller_info[:from_number],
          call_sid: caller_info[:call_sid]
        ).inbound!
      end

      generate_twiml_response

    rescue StandardError => e
      # Log the error
      Rails.logger.error("Error processing incoming call: #{e.message}")

      # Return a simple error TwiML
      error_twiml(e.message)
    end

    def caller_info
      {
        call_sid: params['CallSid'],
        from_number: params['From'],
        to_number: params['To']
      }
    end

    private

    def find_inbox
      # Find the inbox for this phone number
      @inbox = account.inboxes
                      .where(channel_type: 'Channel::Voice')
                      .joins('INNER JOIN channel_voice ON channel_voice.id = inboxes.channel_id')
                      .where('channel_voice.phone_number = ?', caller_info[:to_number])
                      .first

      raise "Inbox not found for phone number #{caller_info[:to_number]}" unless @inbox.present?
    end

    def find_or_create_conversation
      # Delegate conversation creation/lookup to shared service to keep logic in one place
      @conversation = Voice::ConversationFinderService.new(
        account: account,
        phone_number: caller_info[:from_number],
        is_outbound: false,
        inbox: @inbox,
        call_sid: caller_info[:call_sid]
      ).perform

      # Ensure we have a valid conference SID (ConversationFinderService sets it, but be defensive)
      @conversation.reload
      @conference_sid = @conversation.additional_attributes['conference_sid']
      if @conference_sid.blank? || !@conference_sid.match?(/^conf_account_\d+_conv_\d+$/)
        @conference_sid = "conf_account_#{account.id}_conv_#{@conversation.display_id}"
        @conversation.additional_attributes['conference_sid'] = @conference_sid
        @conversation.save!
      end
    end


    def generate_twiml_response
      conference_sid = @conversation.additional_attributes['conference_sid']

      response = Twilio::TwiML::VoiceResponse.new
      response.say(message: 'Thank you for calling. Please wait while we connect you with an agent.')

      # Setup callback URLs
      conference_callback_url = "#{base_url}/api/v1/accounts/#{account.id}/channels/voice/webhooks/conference_status"

      # Now add the caller to the conference
      response.dial do |dial|
        dial.conference(
          conference_sid,
          startConferenceOnEnter: false,
          endConferenceOnExit: true,
          beep: false,
          muted: false,
          waitUrl: '',
          statusCallback: conference_callback_url,
          statusCallbackMethod: 'POST',
          statusCallbackEvent: 'start end join leave',
          participantLabel: "caller-#{caller_info[:call_sid].last(8)}"
        )
      end

      response.to_s
    end

    def error_twiml(_message)
      response = Twilio::TwiML::VoiceResponse.new
      response.say(message: 'We are experiencing technical difficulties with our phone system. Please try again later.')
      response.hangup

      response.to_s
    end

    def base_url
      url = ENV.fetch('FRONTEND_URL', "https://#{params['host_with_port']}")
      url.gsub(%r{/$}, '') # Remove trailing slash if present
    end
  end
end
