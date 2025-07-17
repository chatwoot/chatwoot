module Voice
  class IncomingCallService
    pattr_initialize [:account!, :params!]

    def process
      find_inbox
      create_contact

      # Use a transaction to ensure conversation, message, and call status are all set together
      # This ensures only one conversation.created event with complete call data
      ActiveRecord::Base.transaction do
        create_conversation
        create_voice_call_message
        set_initial_call_status
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

    end

    # Set initial call status within the transaction
    def set_initial_call_status
      # Set call status directly on conversation to avoid separate broadcast
      @conversation.additional_attributes['call_status'] = 'ringing'
      @conversation.additional_attributes['call_started_at'] = Time.now.to_i
      @conversation.save!
      
      # Create activity message directly without CallStatusManager broadcast
      custom_message = "Incoming call from #{@contact.name.presence || caller_info[:from_number]}"
      @conversation.messages.create!(
        account_id: @conversation.account_id,
        inbox_id: @conversation.inbox_id,
        message_type: :activity,
        content: custom_message,
        sender: nil
      )
    end


    def generate_twiml_response
      conference_name = @conversation.additional_attributes['conference_sid']

      response = Twilio::TwiML::VoiceResponse.new
      response.say(message: 'Thank you for calling. Please wait while we connect you with an agent.')

      # Setup callback URLs
      conference_callback_url = "#{base_url}/api/v1/accounts/#{account.id}/channels/voice/webhooks/conference_status"
      call_status_callback_url = "#{base_url}/api/v1/accounts/#{account.id}/channels/voice/webhooks/call_status"

      # Now add the caller to the conference with call status callback
      response.dial(
        action: call_status_callback_url,
        method: 'POST'
      ) do |dial|
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
