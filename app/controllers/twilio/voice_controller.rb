class Twilio::VoiceController < ActionController::Base
  skip_forgery_protection

  def twiml
    # ULTRA minimal TwiML - just a simple greeting and record
    response = Twilio::TwiML::VoiceResponse.new

    # Just a simple message about recent signup and feedback
    response.say(message: 'Hello from Chatwoot. This is a courtesy call to check on your recent signup. We would love to hear any feedback or questions you might have about your experience so far. Please share your thoughts after the beep.')
    response.pause(length: 1) # give a moment before the beep and recording

    # Record their feedback after a beep, then let handle_recording hang up
    response.record(
      action: '/twilio/voice/handle_recording',
      method: 'POST',
      maxLength: 3600,
      timeout: 30,
      playBeep: true
    )

    # Render the response immediately
    render xml: response.to_s, status: :ok
  end

  def handle_user_input
    call_sid = params['CallSid']
    digits = params['Digits']
    speech_result = params['SpeechResult']
    from_number = params['From']
    to_number = params['To']
    direction = params['Direction']
    is_outbound = direction == 'outbound-api'

    # Find the inbox for this voice call based on the direction
    inbox = find_inbox(is_outbound ? from_number : to_number)

    if inbox.present?
      # Create or find the conversation for this call
      conversation = find_or_create_conversation(inbox, is_outbound ? to_number : from_number, call_sid)

      # Create an activity message showing the user input
      input_text = if digits.present?
                     "Caller pressed #{digits}"
                   elsif speech_result.present?
                     "Caller said: \"#{speech_result}\""
                   else
                     'Caller responded'
                   end

      Messages::MessageBuilder.new(
        nil,
        conversation,
        {
          content: input_text,
          message_type: :activity,
          additional_attributes: {
            call_sid: call_sid,
            call_status: 'in-progress',
            user_input: true
          }
        }
      ).perform
    end

    # Redirect back to the main TwiML to continue the call flow
    response = Twilio::TwiML::VoiceResponse.new do |r|
      r.redirect(url: "/twilio/voice/twiml?ReturnCall=true&Direction=#{direction}&step=check_messages")
    end

    render xml: response.to_s, status: :ok
  end

  def handle_recording
    call_sid = params['CallSid']
    recording_url = params['RecordingUrl']
    recording_sid = params['RecordingSid']
    
    # Log the recording information for future implementation
    Rails.logger.info("Recording received: CallSid=#{call_sid}, RecordingSid=#{recording_sid}")
    Rails.logger.info("Recording URL: #{recording_url}")
    
    # Recording functionality has been removed for now
    # In the future, we'll implement this to save call recordings and attach them to conversations
    
    # Return a simple response to end the call
    response = Twilio::TwiML::VoiceResponse.new do |r|
      r.say(message: 'Thank you for your feedback. Goodbye.')
      r.hangup
    end
    render xml: response.to_s, status: :ok
  end

  def transcription_callback
    # Logging transcription details for future implementation
    if params['CallSid'].present?
      Rails.logger.info("Transcription received for CallSid=#{params['CallSid']}")
      Rails.logger.info("Transcription text: #{params['TranscriptionText']}")
      
      # Transcription functionality has been removed for now
      # In the future, we'll implement this to save call transcriptions and attach them to conversations
    end

    # Return an empty TwiML response to satisfy Twilio
    response = Twilio::TwiML::VoiceResponse.new
    render xml: response.to_s, status: :ok
  end

  # This endpoint will be called by Twilio's StatusCallback
  # parameter to notify of call status changes
  def status_callback
    call_sid = params['CallSid']
    call_status = params['CallStatus']
    direction = params['Direction']
    is_outbound = direction == 'outbound-api'
    from_number = params['From']
    to_number = params['To']
    duration = params['CallDuration'] ? params['CallDuration'].to_i : nil

    Rails.logger.info("Twilio status callback: CallSid=#{call_sid}, Status=#{call_status}, Direction=#{direction}")

    # Find the inbox
    inbox = find_inbox(is_outbound ? from_number : to_number)
    return head :ok unless inbox.present?

    # Use ConversationFinderService to find or create the conversation
    contact_number = is_outbound ? to_number : from_number
    # Ensuring contact_number is not blank
    if contact_number.blank?
      Rails.logger.error("Missing phone number in Twilio status callback: CallSid=#{call_sid}")
      return head :ok
    end
    
    conversation = Voice::ConversationFinderService.new(
      account: inbox.account,
      call_sid: call_sid,
      phone_number: contact_number,
      is_outbound: is_outbound,
      inbox: inbox
    ).perform

    # Use the unified CallStatusManager to handle status update
    # The CallStatusManager will determine if the call is outbound internally
    Voice::CallStatus::Manager.new(
      conversation: conversation,
      call_sid: call_sid,
      provider: :twilio
    ).process_status_update(call_status, duration, params['IsFirstResponseForStatus'] == 'true')

    # Return an empty response
    head :ok
  end

  # Simple TwiML with signup follow-up message
  def simple_twiml
    call_sid = params['CallSid']
    from_number = params['From']
    to_number = params['To']
    direction = params['Direction']
    
    # Check if we have an explicit conference_name parameter - for outbound calls
    # This is passed directly from the channel for outbound calls
    conference_name_param = params['conference_name']
    
    # Determine if outbound call
    is_outbound = direction == 'outbound-api'

    # If we have call details, log them and create a conference
    if call_sid.present?
      # Find the inbox for this voice call
      inbox_number = is_outbound ? from_number : to_number
      inbox = find_inbox(inbox_number)

      if inbox.present?
        # Find or create conversation using the service
        contact_number = is_outbound ? to_number : from_number
        
        # Log contact information
        Rails.logger.info("Creating conversation with contact_number=#{contact_number}, call_sid=#{call_sid}")
        
        begin
          conversation = Voice::ConversationFinderService.new(
            account: inbox.account,
            call_sid: call_sid,
            phone_number: contact_number,
            is_outbound: is_outbound,
            inbox: inbox
          ).perform
          
          # Add call activity message using unified CallStatusManager
          # The CallStatusManager will determine if the call is outbound internally
          Voice::CallStatus::Manager.new(
            conversation: conversation,
            call_sid: call_sid,
            provider: :twilio
          ).process_status_update('in-progress', nil, true)
          
          # IMPORTANT: Use the provided conference_name if available, otherwise use the one from conversation
          # Make sure conversation has display_id in all cases - we'll need it for validation
          conversation.reload if conversation.display_id.blank?
          Rails.logger.info("📝 Conversation details - ID: #{conversation.id}, Display ID: #{conversation.display_id}")

          if conference_name_param.present?
            # Use the provided conference name from URL parameter
            conference_name = conference_name_param
            Rails.logger.info("🔍 USING PROVIDED CONFERENCE NAME FROM PARAM: '#{conference_name}'")

            # Validate format - it should be like 'conf_account_123_conv_456'
            if !conference_name.match?(/^conf_account_\d+_conv_\d+$/)
              Rails.logger.warn("⚠️ INCOMING PARAM HAS INVALID CONFERENCE NAME FORMAT: '#{conference_name}'")

              # Generate proper conference name
              fixed_conference_name = "conf_account_#{inbox.account_id}_conv_#{conversation.display_id}"
              Rails.logger.info("🔧 CORRECTING CONFERENCE NAME TO: '#{fixed_conference_name}'")
              conference_name = fixed_conference_name
            end
          else
            # No parameter provided, check conversation data
            conference_name = conversation.additional_attributes['conference_sid'] ||
                             conversation.additional_attributes['conference_name']

            Rails.logger.info("🔍 CHECKING CONVERSATION FOR CONFERENCE NAME: '#{conference_name}'")

            # If still not found or invalid format, generate it
            if conference_name.blank? || !conference_name.match?(/^conf_account_\d+_conv_\d+$/)
              conference_name = "conf_account_#{inbox.account_id}_conv_#{conversation.display_id}"
              Rails.logger.info("🔧 GENERATING NEW CONFERENCE NAME: '#{conference_name}'")
            else
              Rails.logger.info("✅ USING EXISTING CONFERENCE NAME: '#{conference_name}'")
            end
          end

          # Double check the conference name format one last time
          if !conference_name.match?(/^conf_account_\d+_conv_\d+$/)
            Rails.logger.error("‼️ CRITICAL: Conference name still has invalid format: '#{conference_name}'")

            # Force correct format as last resort
            conference_name = "conf_account_#{inbox.account_id}_conv_#{conversation.display_id}"
            Rails.logger.info("🚨 EMERGENCY FIX: Setting conference name to: '#{conference_name}'")
          end
          
          # Store the conference name and other required attributes
          conversation.additional_attributes['conference_sid'] = conference_name
          conversation.additional_attributes['call_direction'] = is_outbound ? 'outbound' : 'inbound'
          conversation.additional_attributes['requires_agent_join'] = true
          
          # Log this critical information
          Rails.logger.info("🚨🚨🚨 CALL: Setting conference_sid=#{conference_name} and requires_agent_join=true")
          
          # Save the conversation
          conversation.save!
          
          # Log the conference creation
          Rails.logger.info("🎧🎧🎧 CALL: Created conference: #{conference_name} for account: #{inbox.account_id}, conversation: #{conversation.display_id}")

          # Generate TwiML that connects the caller to a conference
          response = Twilio::TwiML::VoiceResponse.new
          
          # Simple greeting
          response.say(message: 'Please wait while we connect you to an agent')
          
          # Connect to conference - CRITICAL: Make parameters match the agent side in voice_controller.rb
          response.dial do |dial|
            dial.conference(
              conference_name,
              startConferenceOnEnter: false,     # Caller waits for agent
              endConferenceOnExit: true,         # End when agent leaves
              beep: false,                       # No beep sounds
              muted: false,                      # Caller can speak
              waitUrl: '',                       # No hold music
              earlyMedia: true,                  # Enable early media for faster connection
              statusCallback: "#{base_url}/api/v1/accounts/#{inbox.account_id}/channels/voice/webhooks/conference_status", 
              statusCallbackMethod: 'POST',
              statusCallbackEvent: 'start end join leave',
              participantLabel: "caller-#{call_sid.last(8)}"
            )
          end
          
          render xml: response.to_s, status: :ok
          return
        rescue StandardError => e
          Rails.logger.error("Error creating conversation for voice call: #{e.message}")
          # Continue to fallback TwiML
        end
      end
    end

    # Fallback to simple TwiML if we couldn't set up a conference
    response = Twilio::TwiML::VoiceResponse.new
    response.say(message: 'Hello from Chatwoot. This is a courtesy call to check on your recent signup.')
    response.pause(length: 1)
    response.say(message: 'We will connect you with an agent shortly.')
    response.hangup
    
    render xml: response.to_s, status: :ok
  end

  private

  # Helper method to get base URL with extra resilience
  def base_url
    # Use FRONTEND_URL env variable as the most reliable source for outbound calls
    frontend_url = ENV.fetch('FRONTEND_URL', nil)
    return frontend_url.chomp('/') if frontend_url.present?
    
    # Fallback to request.base_url if available
    if defined?(request) && request&.respond_to?(:base_url) && request.base_url.present?
      return request.base_url
    end
    
    # Last resort fallback
    'http://localhost:3000'
  end

  def find_inbox(phone_number)
    return nil if phone_number.blank?
    
    Inbox.joins('INNER JOIN channel_voice ON channel_voice.account_id = inboxes.account_id AND inboxes.channel_id = channel_voice.id')
         .where('channel_voice.phone_number = ?', phone_number)
         .first
  end

  # Legacy method for backward compatibility
  def find_or_create_conversation(inbox, phone_number, call_sid)
    # Extra validation to avoid passing blank phone numbers
    return nil if phone_number.blank? || inbox.nil?
    
    begin
      Voice::ConversationFinderService.new(
        account: inbox.account,
        call_sid: call_sid,
        phone_number: phone_number,
        is_outbound: false, # Default to inbound for compatibility
        inbox: inbox
      ).perform
    rescue StandardError => e
      Rails.logger.error("Error in find_or_create_conversation: #{e.message}")
      nil
    end
  end

  def get_one_message(call_sid)
    redis_key = "voice_message:#{call_sid}"

    # Get just one message
    redis_message = Redis::Alfred.lpop(redis_key)
    return nil unless redis_message.present?

    begin
      JSON.parse(redis_message)
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse voice message from Redis: #{e.message}")
      nil
    end
  end

  def mark_message_delivered(message_id)
    # Find the message
    message = Message.find_by(id: message_id)
    return unless message.present?

    # Update the message delivery status
    additional_attributes = message.additional_attributes || {}
    additional_attributes[:voice_delivery_status] = 'delivered'
    message.update(additional_attributes: additional_attributes)
  end
end