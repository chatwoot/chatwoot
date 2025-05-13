module Voice
  class IncomingCallService
    pattr_initialize [:account!, :params!]

    def process

      begin
        find_inbox

        return captain_twiml if @inbox.captain_active?

        create_contact

        # Use a transaction to ensure the conversation and voice call message are created together
        # This ensures the voice call message is created before any auto-assignment activity messages
        ActiveRecord::Base.transaction do
          create_conversation
          create_voice_call_message
        end

        # Create activity message separately, after the voice call message
        create_activity_message

        twiml = generate_twiml_response

        twiml
      rescue StandardError => e
        # Log the error
        Rails.logger.error("Error processing incoming call: #{e.message}")

        # Return a simple error TwiML
        error_twiml(e.message)
      end
    end

    def caller_info
      {
        call_sid: params['CallSid'],
        from_number: params['From'],
        to_number: params['To']
      }
    end

    private

    def captain_twiml
      response = Twilio::TwiML::VoiceResponse.new
      
      media_service_url = "#{ENV.fetch('AI_MEDIA_SERVICE_URL', nil)}/incoming-call"

      response.redirect(media_service_url)
      response.to_s
    end

    def find_inbox
      # Find the inbox for this phone number
      @inbox = account.inboxes
                      .where(channel_type: 'Channel::Voice')
                      .joins('INNER JOIN channel_voice ON channel_voice.id = inboxes.channel_id')
                      .where('channel_voice.phone_number = ?', caller_info[:to_number])
                      .first

      raise "Inbox not found for phone number #{caller_info[:to_number]}" unless @inbox.present?

    end

    def create_contact
      # Normalize the phone number
      phone_number = caller_info[:from_number].strip

      # Find or create the contact
      @contact = account.contacts.find_or_create_by!(phone_number: phone_number) do |c|
        c.name = "Contact from #{phone_number}"
      end

    end

    def create_conversation
      # Create or update contact inbox
      @contact_inbox = ContactInbox.find_or_initialize_by(
        contact_id: @contact.id,
        inbox_id: @inbox.id
      )

      # Set source_id if not already set
      @contact_inbox.source_id ||= caller_info[:from_number]
      @contact_inbox.save!


      # Create a new conversation with basic call details
      # Status will be properly set by CallStatusManager later
      @conversation = account.conversations.create!(
        contact_inbox_id: @contact_inbox.id,
        inbox_id: @inbox.id,
        contact_id: @contact.id,
        status: :open,
        additional_attributes: {
          'call_sid' => caller_info[:call_sid],
          'call_direction' => 'inbound',
          'call_initiated_at' => Time.now.to_i,
          'call_type' => 'inbound'
        }
      )

      # Need to reload conversation to get the display_id populated by the database
      @conversation.reload

      # Set up conference name
      conference_name = "conf_account_#{account.id}_conv_#{@conversation.display_id}"
      @conversation.additional_attributes['conference_sid'] = conference_name
      @conversation.save!

    end

    def create_voice_call_message
      # Create a single voice call message from contact for this call
      # Initialize CallStatusManager to get normalized status
      status_manager = Voice::CallStatus::Manager.new(
        conversation: @conversation,
        call_sid: caller_info[:call_sid],
        provider: :twilio
      )
      
      # Get UI-friendly status for consistent display
      ui_status = status_manager.normalized_ui_status('ringing')
      
      message_params = {
        content: 'Voice Call',
        message_type: 'incoming',
        content_type: 'voice_call',
        content_attributes: {
          data: {
            call_sid: caller_info[:call_sid],
            status: ui_status, # Use normalized UI status
            conversation_id: @conversation.display_id,
            call_direction: 'inbound',
            conference_sid: @conversation.additional_attributes['conference_sid'],
            from_number: caller_info[:from_number],
            to_number: caller_info[:to_number],
            meta: {
              created_at: Time.now.to_i,
              ringing_at: Time.now.to_i
            }
          }
        }
      }

      # Create the voice call message only - this ensures it appears first
      @voice_call_message = Messages::MessageBuilder.new(
        @contact,
        @conversation,
        message_params
      ).perform


      # Broadcast call notification
      broadcast_call_status
    end

    # Create activity message separately after the voice call message
    def create_activity_message
      # Use CallStatusManager for consistency
      status_manager = Voice::CallStatus::Manager.new(
        conversation: @conversation,
        call_sid: caller_info[:call_sid],
        provider: :twilio
      )

      # First process ringing status
      status_manager.process_status_update('ringing', nil, true)

      # Then add a custom message about the incoming call - it will be created without a sender
      activity_message = status_manager.create_activity_message(
        "Incoming call from #{@contact.name.presence || caller_info[:from_number]}"
      )
    end

    def broadcast_call_status
      # Get contact name, ensuring we have a valid value
      contact_name_value = @contact.name.presence || caller_info[:from_number]

      # Create the data payload
      broadcast_data = {
        call_sid: caller_info[:call_sid],
        conversation_id: @conversation.display_id,
        inbox_id: @inbox.id,
        inbox_name: @inbox.name,
        inbox_avatar_url: @inbox.avatar_url,
        inbox_phone_number: @inbox.channel.phone_number,
        contact_name: contact_name_value,
        contact_id: @contact.id,
        account_id: account.id,
        phone_number: @contact.phone_number,
        avatar_url: @contact.avatar_url,
        call_direction: 'inbound',
        # CRITICAL: Include the conference_sid
        conference_sid: @conversation.additional_attributes['conference_sid']
      }

      ActionCable.server.broadcast(
        "account_#{account.id}",
        {
          event: 'incoming_call',
          data: broadcast_data
        }
      )

    end

    def generate_twiml_response
      conference_name = @conversation.additional_attributes['conference_sid']
      Rails.logger.info("📞 IncomingCallService: Generating TwiML with conference name: #{conference_name}")

      response = Twilio::TwiML::VoiceResponse.new
      response.say(message: 'Thank you for calling. Please wait while we connect you with an agent.')

      # Setup callback URLs - include conference name and speaker_type in transcription URL
      conference_callback_url = "#{base_url}/api/v1/accounts/#{account.id}/channels/voice/webhooks/conference_status"
      transcription_url = "#{base_url}/twilio/transcription_callback?account_id=#{account.id}&conference_sid=#{conference_name}&speaker_type=contact&contact_id=#{@contact.id}"

      Rails.logger.info("📞 IncomingCallService: Setting transcription callback to: #{transcription_url}")
      Rails.logger.info("📞 IncomingCallService: Setting conference callback to: #{conference_callback_url}")

      # Start real-time transcription for this caller's leg
      response.start do |s|
        s.transcription(
          status_callback_url: transcription_url,
          status_callback_method: 'POST',
          track: 'inbound_track', # Must be inbound_track or outbound_track per Twilio API
          language_code: 'en-US'
        )
      end

      # Now add the caller to the conference
      response.dial do |dial|
        dial.conference(
          conference_name,
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

      result = response.to_s
      Rails.logger.info("📞 IncomingCallService: Generated TwiML: #{result}")
      result
    end

    def error_twiml(message)
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
