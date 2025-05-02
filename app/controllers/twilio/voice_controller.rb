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
    from_number = params['From']
    to_number = params['To']
    recording_url = params['RecordingUrl']
    recording_sid = params['RecordingSid']
    direction = params['Direction']

    # Determine if outbound call
    is_outbound = direction == 'outbound-api'

    # Find inbox and save recording if available
    return unless recording_url.present? && call_sid.present?

    inbox_number = is_outbound ? from_number : to_number
    inbox = find_inbox(inbox_number)

    return unless inbox.present?

    contact_number = is_outbound ? to_number : from_number
    conversation = find_or_create_conversation(inbox, contact_number, call_sid)
    contact = conversation.contact

    # Create a single feedback message for this recording
    return unless contact.present?

    existing_msg = conversation.messages.where('additional_attributes @> ?', { recording_sid: recording_sid }.to_json).first
    return if existing_msg

    begin
      message_params = {
        content: 'Feedback about recent signup',
        message_type: :incoming,
        additional_attributes: {
          call_sid: call_sid,
          recording_url: recording_url,
          recording_sid: recording_sid
        }
      }

      message = Messages::MessageBuilder.new(contact, conversation, message_params).perform

      # Download and attach the recording if we have a valid URL
      if message.present? && recording_url.present?
        begin
          # Validate that the recording URL is accessible
          uri = URI.parse(recording_url)
          if uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
            # Only create an attachment if we have a valid Twilio recording URL
            # Twilio recording URL format: https://api.twilio.com/2010-04-01/Accounts/{AccountSid}/Recordings/{RecordingSid}
            if recording_url.present? && recording_url.include?('/Recordings/') && recording_sid.present?
              # Get authentication details from the channel config to access the recording
              config = inbox.channel.provider_config_hash
              account_sid = config['account_sid']
              auth_token = config['auth_token']

              # Download the recording and attach via ActiveStorage
              recording_mp3_url = "#{recording_url}.mp3"
              download_file = Down.download(
                recording_mp3_url,
                http_basic_authentication: [account_sid, auth_token]
              )
              attachment = message.attachments.new(
                file_type: :audio,
                account_id: inbox.account_id,
                extension: 'mp3',
                fallback_title: 'Voice Recording',
                meta: {
                  recording_sid: recording_sid,
                  twilio_account_sid: account_sid,
                  auth_required: true
                }
              )
              attachment.file.attach(
                io: download_file,
                filename: "#{recording_sid}.mp3",
                content_type: 'audio/mpeg'
              )
              attachment.save!
              Rails.logger.info("Successfully downloaded and attached voice recording: #{recording_url}")
            else
              Rails.logger.error("Invalid Twilio recording URL format or missing SID: #{recording_url}")
            end
          else
            Rails.logger.error("Invalid recording URL format: #{recording_url}")
          end
        rescue StandardError => e
          # Log error but continue
          Rails.logger.error("Error processing recording: #{e.message}")
        end
      end

      # End the call after a single recording
      response = Twilio::TwiML::VoiceResponse.new do |r|
        r.say(message: 'Thank you for your feedback. Goodbye.')
        r.hangup
      end
      render xml: response.to_s, status: :ok
    rescue StandardError => e
      # Log the error but don't crash
      Rails.logger.error("Error processing recording: #{e.message}")
    end
  end

  def transcription_callback
    # Process the transcription asynchronously
    if params['CallSid'].present?
      # Queue the processing as a background job
      CallTranscriptionJob.perform_later(params.permit!.to_h)
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

    Rails.logger.info("Twilio status callback: CallSid=#{call_sid}, Status=#{call_status}, Direction=#{direction}")

    # Find the inbox
    inbox = find_inbox(is_outbound ? from_number : to_number)

    if inbox.present?
      # Find or create the conversation
      conversation = find_or_create_conversation(inbox, is_outbound ? to_number : from_number, call_sid)

      # Add activity for the status change
      track_call_activity(conversation, call_status, false, is_outbound)

      # If call is completed/failed, update conversation status and notify frontend
      if %w[completed busy failed no-answer canceled].include?(call_status)
        # Update conversation with call status
        conversation.additional_attributes ||= {}
        conversation.additional_attributes['call_status'] = call_status
        conversation.additional_attributes['call_ended_at'] = Time.now.to_i
        conversation.status = :resolved
        conversation.save!

        # Publish update to frontend via ActionCable
        ActionCable.server.broadcast(
          "#{conversation.account_id}_#{conversation.inbox_id}",
          {
            event_name: 'call_status_changed',
            data: {
              call_sid: call_sid,
              status: call_status,
              conversation_id: conversation.id
            }
          }
        )

        # Create an activity message for call ending if it's a user hangup
        if call_status == 'completed'
          end_reason = params['CallDuration'] ? 'Call ended by hangup' : 'Call ended'
          call_duration = params['CallDuration'] ? params['CallDuration'].to_i : nil

          Messages::MessageBuilder.new(
            nil,
            conversation,
            {
              content: end_reason,
              message_type: :activity,
              additional_attributes: {
                call_sid: call_sid,
                call_status: call_status,
                call_direction: is_outbound ? 'outbound' : 'inbound',
                call_duration: call_duration
              }
            }
          ).perform
        end
      end
    end

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
        # Find or create conversation 
        contact_number = is_outbound ? to_number : from_number
        conversation = find_or_create_conversation(inbox, contact_number, call_sid)
        
        # Add call activity message
        track_call_activity(conversation, 'in-progress', true, is_outbound)
        
        # IMPORTANT: Use the provided conference_name if available, otherwise create one
        account_id = inbox.account_id
        
        if conference_name_param.present?
          # Use the provided conference name
          conference_name = conference_name_param
          Rails.logger.info("🚨 USING PROVIDED CONFERENCE NAME: '#{conference_name}'")
        else
          # Create a new conference name
          conference_name = "conf_account_#{account_id}_conv_#{conversation.display_id}"
          Rails.logger.info("🚨 CREATED NEW CONFERENCE NAME: '#{conference_name}'")
        end
        
        # Store the conference name in the conversation for the agent to join
        conversation.additional_attributes ||= {}
        conversation.additional_attributes['conference_sid'] = conference_name
        conversation.additional_attributes['call_direction'] = 'outbound'
        conversation.additional_attributes['requires_agent_join'] = true
        
        # Log this critical information
        Rails.logger.info("🚨🚨🚨 OUTBOUND CALL: Setting conference_sid=#{conference_name} and requires_agent_join=true")
        
        # Save the conversation
        conversation.save!
        
        # Log the conference creation
        Rails.logger.info("🎧🎧🎧 OUTBOUND CALL: Created conference: #{conference_name} for account: #{account_id}, conversation: #{conversation.display_id}")

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
            earlyMedia: true,                  # Enable early media for faster connection - ADDED THIS PARAMETER
            statusCallback: "#{base_url}/api/v1/accounts/#{account_id}/channels/voice/webhooks/conference_status", 
            statusCallbackMethod: 'POST',
            statusCallbackEvent: 'start end join leave',
            participantLabel: "caller-#{call_sid.last(8)}"
          )
        end
        
        render xml: response.to_s, status: :ok
        return
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
    Inbox.joins('INNER JOIN channel_voice ON channel_voice.account_id = inboxes.account_id AND inboxes.channel_id = channel_voice.id')
         .where('channel_voice.phone_number = ?', phone_number)
         .first
  end

  def find_or_create_conversation(inbox, phone_number, call_sid)
    account = inbox.account

    # Reuse if existing conversation for this call SID
    existing = account.conversations.where("additional_attributes->>'call_sid' = ?", call_sid).first
    
    # If we found an existing conversation, check if it has a conference_sid
    if existing
      # For outbound calls, we need to ensure it has a conference_sid
      if existing.additional_attributes['conference_sid'].blank?
        # Create a conference name in the same format as inbound calls
        conference_name = "conf_account_#{account.id}_conv_#{existing.display_id}"
        existing.additional_attributes['conference_sid'] = conference_name
        existing.save!
        Rails.logger.info("🎧🎧🎧 ADDED CONFERENCE_SID to existing conversation: #{conference_name}")
      end
      return existing
    end

    # Ensure contact and inbox
    contact = account.contacts.find_or_create_by(phone_number: phone_number) do |c|
      c.name = "Contact from #{phone_number}"
    end
    contact_inbox = ContactInbox.find_or_initialize_by(contact_id: contact.id, inbox_id: inbox.id)
    contact_inbox.source_id ||= phone_number
    contact_inbox.save!

    # Create new conversation for this call
    convo = account.conversations.create!(contact_inbox_id: contact_inbox.id, inbox_id: inbox.id, status: :open)
    
    # Create a conference name using the same format for consistency
    conference_name = "conf_account_#{account.id}_conv_#{convo.display_id}"
    
    convo.additional_attributes = { 
      'call_sid' => call_sid, 
      'call_status' => 'in-progress',
      'conference_sid' => conference_name
    }
    convo.save!
    
    Rails.logger.info("🎧🎧🎧 Created new conversation with conference_sid: #{conference_name}")
    convo
  end

  def track_call_activity(conversation, call_status, is_first_response, is_outbound)
    return unless conversation.present?

    # Only create status messages when status changes or on first response
    prev_status = conversation.additional_attributes&.dig('call_status')
    return if !is_first_response && prev_status == call_status

    # Update conversation with call status
    conversation.additional_attributes ||= {}
    conversation.additional_attributes['call_status'] = call_status
    conversation.save!

    # Create an appropriate activity message based on status
    activity_message = case call_status
                       when 'ringing'
                         is_outbound ? 'Outbound call initiated' : 'Phone ringing'
                       when 'in-progress'
                         if is_first_response
                           is_outbound ? 'Call connected' : 'Call answered'
                         else
                           'Call in progress'
                         end
                       when 'completed', 'busy', 'failed', 'no-answer', 'canceled'
                         "Call #{call_status}"
                       else
                         "Call status: #{call_status}"
                       end

    Messages::MessageBuilder.new(
      nil,
      conversation,
      {
        content: activity_message,
        message_type: :activity,
        additional_attributes: {
          call_sid: conversation.additional_attributes&.dig('call_sid'),
          call_status: call_status,
          call_direction: is_outbound ? 'outbound' : 'inbound'
        }
      }
    ).perform
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
