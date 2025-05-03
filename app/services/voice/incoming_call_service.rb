module Voice
  class IncomingCallService
    pattr_initialize [:account!, :params!]

    def process
      create_contact
      create_conversation
      create_conversation_messages
      generate_twiml_response
    end

    def caller_info
      {
        call_sid: params['CallSid'],
        from_number: params['From'],
        to_number: params['To']
      }
    end

    private

    def create_contact
      @contact = account.contacts.find_or_create_by!(phone_number: caller_info[:from_number]) do |c|
        c.name = "Contact from #{caller_info[:from_number]}"
      end
    end

    def create_conversation
      # Find the inbox for this phone number
      @inbox = find_voice_inbox

      # Create or update contact inbox
      contact_inbox = create_contact_inbox

      # Create a new conversation with call details
      @conversation = account.conversations.create!(
        contact_inbox_id: contact_inbox.id,
        inbox_id: @inbox.id,
        status: :open,
        contact: @contact,
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

      Rails.logger.info("🎧 Creating conference: #{conference_name} for account: #{account.id}, conversation: #{@conversation.display_id}")
    end

    def create_conversation_messages
      # Create a single incoming message from contact for this call
      Messages::MessageBuilder.new(
        @contact, # For incoming calls, sender is the contact
        @conversation,
        {
          content: 'Voice Call',
          message_type: :incoming,
          content_type: 'voice_call', # Direct content type for voice calls
          content_attributes: {
            data: {
              call_sid: caller_info[:call_sid],
              status: 'ringing',
              conversation_id: @conversation.id,
              call_direction: 'inbound',
              meta: {
                created_at: Time.now.to_i
              }
            }
          }
        }
      ).perform

      # Create a simple activity message (no sender needed)
      Messages::MessageBuilder.new(
        nil, # Activity messages don't need a sender
        @conversation,
        {
          content: "Incoming call from #{@contact.name.presence || caller_info[:from_number]}",
          message_type: :activity,
          additional_attributes: {
            call_sid: caller_info[:call_sid],
            call_status: 'ringing',
            call_direction: 'inbound'
          }
        }
      ).perform

      # Broadcast call notification
      broadcast_call_status
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
    end

    def generate_twiml_response
      conference_name = @conversation.additional_attributes['conference_sid']
      
      response = Twilio::TwiML::VoiceResponse.new
      response.say(message: 'Thank you for calling. Please wait while we connect you with an agent.')
      
      response.dial do |dial|
        dial.conference(
          conference_name,
          startConferenceOnEnter: false,
          endConferenceOnExit: true,
          beep: false,
          muted: false,
          waitUrl: '',
          statusCallback: "#{base_url.gsub(/\/$/, '')}/api/v1/accounts/#{account.id}/channels/voice/webhooks/conference_status", 
          statusCallbackMethod: 'POST',
          statusCallbackEvent: 'start end join leave',
          participantLabel: "caller-#{caller_info[:call_sid].last(8)}"
        )
      end
      
      response.to_s
    end

    def find_voice_inbox
      account.inboxes
             .where(channel_type: 'Channel::Voice')
             .joins('INNER JOIN channel_voice ON channel_voice.id = inboxes.channel_id')
             .where('channel_voice.phone_number = ?', caller_info[:to_number])
             .first or raise "Inbox not found for phone number #{caller_info[:to_number]}"
    end

    def create_contact_inbox
      contact_inbox = ContactInbox.find_or_create_by!(
        contact_id: @contact.id,
        inbox_id: @inbox.id
      )
      contact_inbox.update!(source_id: caller_info[:from_number]) if contact_inbox.source_id.blank?
      contact_inbox
    end

    def base_url
      ENV.fetch('FRONTEND_URL', "https://#{params['host_with_port']}")
    end
  end
end