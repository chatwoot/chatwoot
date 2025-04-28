class Twilio::VoiceController < ActionController::Base
  skip_forgery_protection
  
  def twiml
    # ULTRA minimal TwiML - just a simple greeting and record
    response = Twilio::TwiML::VoiceResponse.new
    
    # Just a simple message about recent signup and feedback
    response.say(message: 'Hello from Chatwoot. This is a courtesy call to check on your recent signup. We would love to hear any feedback or questions you might have about your experience so far. Please share your thoughts after the beep.')
    
    # Record their feedback
    response.record(
      action: '/twilio/voice/handle_recording',
      method: 'POST',
      maxLength: 30,
      timeout: 2,
      statusCallback: '/twilio/voice/status_callback',
      statusCallbackMethod: 'POST',
      statusCallbackEvent: ['completed']
    )
    
    # Always end the call to avoid any complexity
    response.hangup
    
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
                    "Caller responded"
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
      r.redirect(url: "/twilio/voice/twiml?ReturnCall=true&Direction=#{direction.to_s}&step=check_messages")
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
    if recording_url.present? && call_sid.present?
      inbox_number = is_outbound ? from_number : to_number
      inbox = find_inbox(inbox_number)
      
      if inbox.present?
        contact_number = is_outbound ? to_number : from_number
        conversation = find_or_create_conversation(inbox, contact_number, call_sid)
        contact = conversation.contact
        
        # Create a message with the recording
        if contact.present?
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
                    
                    # Create an authenticated URL that includes auth details
                    # This is needed because Twilio recording URLs require authentication
                    recording_mp3_url = "#{recording_url}.mp3"
                    
                    begin
                      # Create an attachment record with proper file type for audio
                      attachment = message.attachments.new(
                        file_type: :audio, # Use audio type for proper player rendering
                        account_id: inbox.account_id,
                        external_url: recording_mp3_url,
                        fallback_title: 'Voice Recording',
                        meta: {
                          recording_sid: recording_sid,
                          twilio_account_sid: account_sid,
                          auth_required: true
                        }
                      )
                      
                      # Save the attachment
                      if attachment.save
                        Rails.logger.info("Successfully attached voice recording from #{recording_url}")
                      else
                        Rails.logger.error("Failed to save attachment: #{attachment.errors.full_messages.join(', ')}")
                      end
                    rescue => e
                      Rails.logger.error("Failed to handle recording: #{e.message}")
                      
                      # If the audio attachment fails, try with a more generic file type
                      begin
                        fallback_attachment = message.attachments.new(
                          file_type: :file,
                          account_id: inbox.account_id,
                          external_url: recording_mp3_url,
                          fallback_title: 'Voice Recording (.mp3)',
                          meta: {
                            recording_sid: recording_sid,
                            twilio_account_sid: account_sid,
                            auth_required: true
                          }
                        )
                        fallback_attachment.save
                      rescue => e
                        Rails.logger.error("Failed to create fallback attachment: #{e.message}")
                      end
                    end
                  else
                    Rails.logger.error("Invalid Twilio recording URL format or missing SID: #{recording_url}")
                  end
                else
                  Rails.logger.error("Invalid recording URL format: #{recording_url}")
                end
              rescue => e
                # Log error but continue
                Rails.logger.error("Error processing recording: #{e.message}")
              end
            end
            
            # Loop recording until caller hangs up
            response = Twilio::TwiML::VoiceResponse.new
            response.say(message: 'Segment recorded. Please leave more feedback after the beep, or hang up to finish.')
            response.record(
              action: '/twilio/voice/handle_recording',
              method: 'POST',
              maxLength: 30,
              timeout: 2,
              playBeep: true,
              statusCallback: '/twilio/voice/status_callback',
              statusCallbackMethod: 'POST',
              statusCallbackEvent: ['completed', 'in-progress', 'absent']
            )
            render xml: response.to_s, status: :ok
          rescue => e
            # Log the error but don't crash
            Rails.logger.error("Error processing recording: #{e.message}")
          end
        end
      end
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
      if ['completed', 'busy', 'failed', 'no-answer', 'canceled'].include?(call_status)
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
    
    # Determine if outbound call
    is_outbound = direction == 'outbound-api'
    
    response = Twilio::TwiML::VoiceResponse.new
    
    # The signup follow-up message
    response.say(message: 'Hello from Chatwoot. This is a courtesy call to check on your recent signup. We would love to hear any feedback or questions you might have about your experience so far. Please share your thoughts after the beep.')
    
    # Record their feedback
    response.record(
      action: '/twilio/voice/handle_recording',
      method: 'POST',
      maxLength: 60,
      timeout: 3,
      statusCallback: '/twilio/voice/status_callback',
      statusCallbackMethod: 'POST',
      statusCallbackEvent: ['completed', 'in-progress', 'absent']
    )
    
    # End the call
    response.hangup
    
    # If we have call details, log them for the conversation
    if call_sid.present?
      # Find the inbox for this voice call
      inbox_number = is_outbound ? from_number : to_number
      inbox = find_inbox(inbox_number)
      
      if inbox.present?
        # Create or find conversation
        contact_number = is_outbound ? to_number : from_number
        conversation = find_or_create_conversation(inbox, contact_number, call_sid)
        
        # Add call activity message
        track_call_activity(conversation, 'in-progress', true, is_outbound)
      end
    end
    
    render xml: response.to_s, status: :ok
  end
  
  private
  
  def find_inbox(phone_number)
    Inbox.joins("INNER JOIN channel_voice ON channel_voice.account_id = inboxes.account_id AND inboxes.channel_id = channel_voice.id")
      .where("channel_voice.phone_number = ?", phone_number)
      .first
  end
  
  def find_or_create_conversation(inbox, phone_number, call_sid)
    account = inbox.account
    
    # Reuse if existing conversation for this call SID
    existing = account.conversations.where("additional_attributes->>'call_sid' = ?", call_sid).first
    return existing if existing
    
    # Ensure contact and inbox
    contact = account.contacts.find_or_create_by(phone_number: phone_number) do |c|
      c.name = "Contact from #{phone_number}"
    end
    contact_inbox = ContactInbox.find_or_initialize_by(contact_id: contact.id, inbox_id: inbox.id)
    contact_inbox.source_id ||= phone_number
    contact_inbox.save!
    
    # Create new conversation for this call
    convo = account.conversations.create!(contact_inbox_id: contact_inbox.id, inbox_id: inbox.id, status: :open)
    convo.additional_attributes = { 'call_sid' => call_sid, 'call_status' => 'in-progress' }
    convo.save!
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
      message = JSON.parse(redis_message)
      return message
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse voice message from Redis: #{e.message}")
      return nil
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