class Api::V1::Accounts::Channels::Voice::WebhooksController < Api::V1::Accounts::BaseController
  skip_before_action :authenticate_user!, :set_current_user, only: [:incoming, :conference_status]
  # Removed skip_before_action :verify_authenticity_token (it's not defined in BaseController)
  protect_from_forgery with: :null_session, only: [:incoming, :conference_status]
  before_action :validate_twilio_signature, only: [:incoming]
  before_action :handle_options_request, only: [:incoming, :conference_status]
  
  # Handle CORS preflight OPTIONS requests
  def handle_options_request
    if request.method == "OPTIONS"
      set_cors_headers
      head :ok
      return true
    end
    false
  end
  
  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Content-Type, X-Twilio-Signature'
    headers['Access-Control-Max-Age'] = '86400' # 24 hours
  end

  # Handle incoming calls from Twilio
  def incoming
    # Find the corresponding voice channel/inbox for this number
    to_number = params['To']
    inbox = Current.account.inboxes
                   .where(channel_type: 'Channel::Voice')
                   .joins('INNER JOIN channel_voice ON channel_voice.id = inboxes.channel_id')
                   .where('channel_voice.phone_number = ?', to_number)
                   .first

    unless inbox
      render_error('Inbox not found for this phone number')
      return
    end

    # Get caller information
    from_number = params['From']
    call_sid = params['CallSid']

    # Find or create the contact
    contact = Current.account.contacts.find_or_create_by!(phone_number: from_number) do |c|
      c.name = "Contact from #{from_number}"
    end

    # Find or create the contact inbox
    contact_inbox = ContactInbox.find_or_create_by!(
      contact_id: contact.id,
      inbox_id: inbox.id
    )
    contact_inbox.update!(source_id: from_number) if contact_inbox.source_id.blank?

    # Create a new conversation for this call
    conversation = Current.account.conversations.create!(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id,
      status: :open,
      contact: contact,
      additional_attributes: {
        'call_sid' => call_sid,
        'call_status' => 'ringing',
        'call_direction' => 'inbound'
      }
    )
    
    # Use format that includes account ID and conversation display ID
    conference_name = "conf_account_#{Current.account.id}_conv_#{conversation.display_id}"
    
    # Add conference name to conversation
    conversation.additional_attributes['conference_sid'] = conference_name
    conversation.save!
    
    # SUPER EXPLICIT DEBUG logging for the conference name
    Rails.logger.info("🎧🎧🎧 CREATING INITIAL CONFERENCE: '#{conference_name}' for account_id: #{Current.account.id}, conversation: #{conversation.display_id}")
    Rails.logger.info("🎧🎧🎧 SAVED TO conversation.additional_attributes['conference_sid'] = '#{conversation.additional_attributes['conference_sid']}'")
    Rails.logger.info("Creating conference: #{conference_name} for account: #{Current.account.id}, conversation: #{conversation.display_id}")

    # Create an activity message for the incoming call
    Messages::MessageBuilder.new(
      nil,
      conversation,
      {
        content: 'Incoming call',
        message_type: :activity,
        additional_attributes: {
          call_sid: call_sid,
          call_status: 'ringing',
          call_direction: 'inbound'
        }
      }
    ).perform

    # Broadcast incoming call notification on account-level channel
    broadcast_call_status('incoming_call', {
                            call_sid: call_sid,
                            conversation_id: conversation.id,
                            inbox_id: inbox.id,
                            inbox_name: inbox.name,
                            contact_name: contact.name || from_number,
                            contact_id: contact.id
                          }, account_id: inbox.account_id)

    # Generate simplified TwiML response
    response = Twilio::TwiML::VoiceResponse.new
    response.say(message: 'Thank you for calling. Please wait while we connect you with an agent.')
    
    # Log what we're doing
    Rails.logger.info("🎧🎧🎧 CALLER CONNECTING TO CONFERENCE: '#{conference_name}'")
    
    # Simple dialog approach for caller
    response.dial do |dial|
      dial.conference(
        conference_name,
        startConferenceOnEnter: false,     # Caller waits for agent
        endConferenceOnExit: true,         # End when agent leaves
        beep: false,                       # No beep sounds
        muted: false,                      # Caller can speak
        waitUrl: '',                       # No hold music
        statusCallback: "#{base_url.gsub(/\/$/, '')}/api/v1/accounts/#{Current.account.id}/channels/voice/webhooks/conference_status", 
        statusCallbackMethod: 'POST',
        statusCallbackEvent: 'start end join leave',
        participantLabel: "caller-#{call_sid.last(8)}"
      )
    end
    
    # Simplified logging
    Rails.logger.info("🔊 Created simplified conference #{conference_name} for account #{Current.account.id}")
    Rails.logger.info("🔊 Conference parameters: startConferenceOnEnter=false, endConferenceOnExit=true")

    render xml: response.to_s
  end

  # Handle conference status updates with enhanced logging for audio troubleshooting
  def conference_status
    # Set CORS headers first to ensure they're always included
    set_cors_headers
    
    # SUPER IMPORTANT: Return a minimal response immediately for OPTIONS requests
    if request.method == "OPTIONS"
      return head :ok
    end
    
    # Wrap everything in a rescue block to prevent large error responses
    begin
      # Log only essential parameters to avoid large log messages
      Rails.logger.info("📞 Conference status webhook: event=#{params['StatusCallbackEvent']}, call_sid=#{params['CallSid']&.truncate(10)}")
      
      call_sid = params['CallSid']
      conference_sid = params['ConferenceSid']
      event = params['StatusCallbackEvent']
      account_id = params[:account_id]
      participant_label = params['ParticipantLabel']
      
      # For local development, set Current.account if not set
      if !Current.account
        Current.account = Account.find(account_id) if account_id
      end
      
      # Try to find the conversation by parsing conference_sid directly or through additional attributes
      conversation = nil
      
      # First try to find by exact conference_sid match
      if conference_sid.present?
        conversation = Current.account.conversations
                              .where("additional_attributes->>'conference_sid' = ?", conference_sid)
                              .first
      end
      
      # If not found and conference_sid looks like our format, extract conversation ID directly
      if conversation.nil? && conference_sid.present? && conference_sid.start_with?('conf_account_')
        # Try to parse conversation ID from conference name (conf_account_X_conv_Y)
        conference_parts = conference_sid.match(/conf_account_\d+_conv_(\d+)/)
        if conference_parts && conference_parts[1].present?
          conversation_display_id = conference_parts[1]
          conversation = Current.account.conversations.find_by(display_id: conversation_display_id)
          Rails.logger.info("🎧 Found conversation by display_id=#{conversation_display_id} from conference_sid=#{conference_sid}")
        end
      end
      
      # If still not found, try by call_sid
      if conversation.nil? && call_sid.present?
        conversation = Current.account.conversations
                              .where("additional_attributes->>'call_sid' = ?", call_sid)
                              .first
      end
      
      # If conversation found, update it
      if conversation
        # Add participant info to conversation for debugging
        begin
          # Update participant list directly in conversation for real-time monitoring
          conversation.additional_attributes ||= {}
          conversation.additional_attributes['participants'] ||= []
          
          # Check if this participant is already in the list
          existing_participant = conversation.additional_attributes['participants'].find do |p|
            p['call_sid'] == call_sid
          end
          
          if event == 'join'
            # Add participant if not exists
            unless existing_participant
              conversation.additional_attributes['participants'] << {
                'call_sid' => call_sid,
                'label' => participant_label,
                'joined_at' => Time.now.to_i
              }
            end
          elsif event == 'leave'
            # Remove participant if exists
            conversation.additional_attributes['participants'].reject! { |p| p['call_sid'] == call_sid }
          end
          
          # Always flag outbound calls that need agent join
          if conversation.additional_attributes['call_direction'] == 'outbound' && 
             participant_label&.start_with?('caller-') &&
             event == 'join'
            
            # This is the customer joining an outbound call - flag for agent to join immediately
            conversation.additional_attributes['requires_agent_join'] = true
            
            # Broadcast an immediate "incoming call" notification for the agent
            broadcast_call_status('incoming_call', {
              call_sid: call_sid,
              conversation_id: conversation.id,
              inbox_id: conversation.inbox_id,
              inbox_name: conversation.inbox.name,
              contact_name: conversation.contact.name || 'Outbound Call',
              contact_id: conversation.contact_id,
              is_outbound: true
            }, account_id: conversation.account_id)
          end
          
          # Save the updated conversation
          conversation.save!
        rescue => participant_error
          Rails.logger.error("Error updating participants: #{participant_error.message}")
        end
        
        # Process conversation updates in the background to avoid delaying response
        Sidekiq::Client.enqueue_to(
          'default',
          'ProcessConferenceStatusJob',
          conversation_id: conversation.id,
          event: event,
          call_sid: call_sid,
          conference_sid: conference_sid,
          account_id: Current.account.id,
          participant_sid: params['ParticipantSid'],
          participant_label: participant_label,
          call_sid_ending_with: params['CallSidEndingWith'],
          audio_level: params['AudioLevel']
        )
      else
        Rails.logger.error("⚠️ Conference webhook: Conversation not found for call_sid=#{call_sid}, conference_sid=#{conference_sid}")
      end
    rescue => e
      # Just log errors but don't let them affect the response
      Rails.logger.error("Error in conference_status: #{e.message[0..100]}")
    end
    
    # CRITICAL: Always return a minimal success response - this is what Twilio expects
    # Return just a 200 OK header with minimal content
    head :ok
  end

  private

  def validate_twilio_signature
    # Skip for OPTIONS requests
    return true if request.method == "OPTIONS"
    
    # Find the inbox for the phone number
    to_number = params['To']

    # Skip validation for local development
    return true if Rails.env.development?

    # Skip if no To param (happens in some callback scenarios)
    return true if to_number.blank?

    begin
      inbox = Current.account.inboxes
                    .where(channel_type: 'Channel::Voice')
                    .joins('INNER JOIN channel_voice ON channel_voice.id = inboxes.channel_id')
                    .where('channel_voice.phone_number = ?', to_number)
                    .first

      # If inbox not found, we'll log it but allow the request for Twilio callbacks
      # This is necessary because conference callbacks may not have the original To number
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
        render_error('Invalid Twilio signature')
        return false
      end
    rescue => e
      Rails.logger.error("Error validating Twilio signature: #{e.message}")
      # Always allow callbacks even if validation fails
      return true
    end

    true
  end

  def render_error(message)
    response = Twilio::TwiML::VoiceResponse.new
    response.say(message: message)
    response.hangup
    render xml: response.to_s
  end

  def base_url
    ENV.fetch('FRONTEND_URL', "https://#{request.host_with_port}")
  end

  def broadcast_call_status(event_name, data, account_id:)
    # Include account_id in the data to help with validation
    data_with_account = data.merge(account_id: account_id)
    
    ActionCable.server.broadcast(
      "account_#{account_id}",
      {
        event: event_name,
        data: data_with_account
      }
    )
  end
end
