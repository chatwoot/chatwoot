module Voice
  class IncomingCallService
    pattr_initialize [:account!, :params!]

    def process
      Rails.logger.info("🔍 INCOMING CALL: Starting processing for call_sid=#{caller_info[:call_sid]}")
      Rails.logger.info("📞 CALL DETAILS: From=#{caller_info[:from_number]} To=#{caller_info[:to_number]}")

      begin
        find_inbox
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

        Rails.logger.info("✅ INCOMING CALL: Successfully processed for call_sid=#{caller_info[:call_sid]}")
        twiml
      rescue StandardError => e
        Rails.logger.error("❌ INCOMING CALL ERROR: #{e.message}")
        Rails.logger.error("❌ INCOMING CALL BACKTRACE: #{e.backtrace[0..5].join("\n")}")

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

    def find_inbox
      # Find the inbox for this phone number
      @inbox = account.inboxes
                      .where(channel_type: 'Channel::Voice')
                      .joins('INNER JOIN channel_voice ON channel_voice.id = inboxes.channel_id')
                      .where('channel_voice.phone_number = ?', caller_info[:to_number])
                      .first

      raise "Inbox not found for phone number #{caller_info[:to_number]}" unless @inbox.present?

      Rails.logger.info("📥 FOUND INBOX: inbox_id=#{@inbox.id} for phone=#{caller_info[:to_number]}")
    end

    def create_contact
      # Normalize the phone number
      phone_number = caller_info[:from_number].strip

      # Find or create the contact
      @contact = account.contacts.find_or_create_by!(phone_number: phone_number) do |c|
        c.name = "Contact from #{phone_number}"
      end

      Rails.logger.info("👤 CONTACT: contact_id=#{@contact.id} name=#{@contact.name} phone=#{@contact.phone_number}")
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

      Rails.logger.info("📬 CONTACT INBOX: id=#{@contact_inbox.id} source_id=#{@contact_inbox.source_id}")

      # Create a new conversation with call details
      @conversation = account.conversations.create!(
        contact_inbox_id: @contact_inbox.id,
        inbox_id: @inbox.id,
        contact_id: @contact.id,
        status: :open,
        additional_attributes: {
          'call_sid' => caller_info[:call_sid],
          'call_status' => 'ringing',
          'call_direction' => 'inbound',
          'call_initiated_at' => Time.now.to_i,
          'call_type' => 'inbound'
        }
      )

      # Set up conference name
      conference_name = "conf_account_#{account.id}_conv_#{@conversation.display_id}"
      @conversation.additional_attributes['conference_sid'] = conference_name
      @conversation.save!

      Rails.logger.info("💬 CONVERSATION: id=#{@conversation.id} display_id=#{@conversation.display_id} conference=#{conference_name}")
    end

    def create_voice_call_message
      # Create a single voice call message from contact for this call
      message_params = {
        content: 'Voice Call',
        message_type: 'incoming',
        content_type: 'voice_call',
        content_attributes: {
          data: {
            call_sid: caller_info[:call_sid],
            status: 'ringing',
            conversation_id: @conversation.id,
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

      Rails.logger.info("✉️ VOICE CALL MESSAGE: id=#{@voice_call_message.id} content_type=#{@voice_call_message.content_type}")

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

      # Then add a custom message about the incoming call
      activity_message = status_manager.create_activity_message(
        "Incoming call from #{@contact.name.presence || caller_info[:from_number]}"
      )

      Rails.logger.info("📝 ACTIVITY MESSAGE: id=#{activity_message.id}")
    end

    def broadcast_call_status
      ActionCable.server.broadcast(
        "account_#{account.id}",
        {
          event: 'incoming_call',
          data: {
            call_sid: caller_info[:call_sid],
            conversation_id: @conversation.id,
            inbox_id: @inbox.id,
            inbox_name: @inbox.name,
            contact_name: @contact.name || caller_info[:from_number],
            contact_id: @contact.id,
            account_id: account.id
          }
        }
      )

      Rails.logger.info('📢 BROADCAST: Sent incoming_call notification')
    end

    def generate_twiml_response
      conference_name = @conversation.additional_attributes['conference_sid']

      response = Twilio::TwiML::VoiceResponse.new
      response.say(message: 'Thank you for calling. Please wait while we connect you with an agent.')

      callback_url = "#{base_url}/api/v1/accounts/#{account.id}/channels/voice/webhooks/conference_status"
      Rails.logger.info("🔗 CONFERENCE CALLBACK URL: #{callback_url}")

      response.dial do |dial|
        dial.conference(
          conference_name,
          startConferenceOnEnter: false,
          endConferenceOnExit: true,
          beep: false,
          muted: false,
          waitUrl: '',
          statusCallback: callback_url,
          statusCallbackMethod: 'POST',
          statusCallbackEvent: 'start end join leave',
          participantLabel: "caller-#{caller_info[:call_sid].last(8)}"
        )
      end

      Rails.logger.info("📞 TWIML: Generated conference TwiML for #{conference_name}")
      response.to_s
    end

    def error_twiml(message)
      response = Twilio::TwiML::VoiceResponse.new
      response.say(message: 'We are experiencing technical difficulties with our phone system. Please try again later.')
      response.hangup

      Rails.logger.info("❌ ERROR TWIML: Generated error TwiML due to: #{message}")
      response.to_s
    end

    def base_url
      url = ENV.fetch('FRONTEND_URL', "https://#{params['host_with_port']}")
      Rails.logger.info("🌐 BASE URL: Using #{url}")
      url.gsub(%r{/$}, '') # Remove trailing slash if present
    end
  end
end
