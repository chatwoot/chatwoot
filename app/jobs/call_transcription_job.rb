class CallTranscriptionJob < ApplicationJob
  queue_as :low

  def perform(params)
    call_sid = params['CallSid']
    recording_url = params['RecordingUrl']
    recording_sid = params['RecordingSid']
    to_number = params['To']
    from_number = params['From']
    direction = params['Direction']
    call_status = params['CallStatus']
    
    # Determine if this is an outbound call
    is_outbound = direction == 'outbound-api'
    
    # Find the inbox for this voice call based on the direction
    # For outbound calls, the "From" is the Chatwoot number
    # For inbound calls, the "To" is the Chatwoot number
    channel_number = is_outbound ? from_number : to_number
    
    inbox = Inbox.joins("INNER JOIN channel_voice ON channel_voice.account_id = inboxes.account_id AND inboxes.channel_id = channel_voice.id")
      .where("channel_voice.phone_number = ?", channel_number)
      .first
      
    return if inbox.nil?
    
    account = inbox.account
    
    # For outbound calls, the contact is the person being called (To)
    # For inbound calls, the contact is the caller (From)
    contact_number = is_outbound ? to_number : from_number
    
    # Find or create the contact
    contact = account.contacts.find_or_create_by(phone_number: contact_number) do |c|
      c.name = is_outbound ? "Customer at #{contact_number}" : "Caller from #{contact_number}"
    end
    
    # Find or create the contact inbox
    contact_inbox = ContactInbox.find_or_initialize_by(
      contact_id: contact.id,
      inbox_id: inbox.id
    )
    
    # Set the source_id if it's a new record
    if contact_inbox.new_record?
      contact_inbox.source_id = from_number
    end
    
    contact_inbox.save!
    
    # Find or create a conversation for this call
    conversation = account.conversations.find_or_create_by(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id
    ) do |conv|
      conv.status = :open
    end
    
    # If the conversation was auto-resolved, reopen it
    if conversation.resolved?
      conversation.toggle_status
    end
    
    # If we have a transcription, add it to an existing message or create a new one
    if params['TranscriptionText'].present?
      # Look for a recent message from this recording
      recording_message = conversation.messages
                                    .where("additional_attributes @> ?", { recording_sid: recording_sid }.to_json)
                                    .order(created_at: :desc)
                                    .first
      
      if recording_message
        # Update existing message with transcription
        recording_message.content = params['TranscriptionText']
        recording_message.additional_attributes[:transcription] = params['TranscriptionText']
        recording_message.save!
      else
        # Create a new message with the transcription
        message_params = {
          content: params['TranscriptionText'],
          message_type: :incoming,
          additional_attributes: { 
            is_transcription: true,
            call_sid: call_sid,
            recording_sid: recording_sid,
            recording_url: recording_url
          },
          source_id: "transcription_#{recording_sid}"
        }
        
        message = Messages::MessageBuilder.new(contact, conversation, message_params).perform
        
        # Attach the recording as an attachment if it's a valid Twilio recording URL
        if recording_url.present? && recording_url.include?('/Recordings/') && recording_sid.present?
          begin
            # Get authentication details from the channel config to access the recording
            config = inbox.channel.provider_config_hash
            account_sid = config['account_sid']
            auth_token = config['auth_token']
            
            # Create an authenticated URL that includes auth details
            # Format for MP3 playback
            recording_mp3_url = "#{recording_url}.mp3"
            
            attachment_params = {
              file_type: :audio,
              account_id: inbox.account_id,
              external_url: recording_mp3_url,
              fallback_title: 'Voice recording',
              meta: {
                recording_sid: recording_sid,
                twilio_account_sid: account_sid,
                auth_required: true,
                transcription: params['TranscriptionText']
              }
            }
            attachment = message.attachments.new(attachment_params)
            attachment.save!
            Rails.logger.info("Successfully attached voice recording from #{recording_url}")
          rescue StandardError => e
            Rails.logger.error("Error attaching voice recording: #{e.message}")
            
            # Try with a more general file type if audio fails
            begin
              fallback_attachment = message.attachments.new(
                file_type: :file,
                account_id: inbox.account_id,
                external_url: recording_mp3_url,
                fallback_title: 'Voice Recording (.mp3)',
                meta: {
                  recording_sid: recording_sid,
                  twilio_account_sid: account_sid,
                  auth_required: true,
                  transcription: params['TranscriptionText']
                }
              )
              fallback_attachment.save!
            rescue StandardError => e
              Rails.logger.error("Failed to create fallback attachment: #{e.message}")
            end
          end
        else
          Rails.logger.error("Invalid Twilio recording URL format or missing SID: #{recording_url}")
        end
      end
    end
    
    # Create or update call status information
    call_info_message = conversation.messages
                                  .where("additional_attributes @> ?", { call_sid: call_sid, message_type: 'activity' }.to_json)
                                  .first
    
    message_attributes = {
      call_sid: call_sid,
      call_status: params['CallStatus'] || 'in-progress'
    }
    
    # Add recording details if available
    if recording_url.present?
      message_attributes[:recordings_count] = (call_info_message&.additional_attributes&.dig(:recordings_count) || 0) + 1
      message_attributes[:latest_recording_url] = recording_url
      message_attributes[:latest_recording_sid] = recording_sid
      message_attributes[:call_duration] = params['RecordingDuration']
    end
    
    if call_info_message.present?
      # Update the existing call info message
      call_info_message.additional_attributes.merge!(message_attributes)
      call_info_message.save!
    else
      # Create a new call info message
      message_params = {
        content: 'Voice call in progress',
        message_type: :activity,
        additional_attributes: message_attributes,
        source_id: "voice_call_#{call_sid}"
      }
      
      Messages::MessageBuilder.new(nil, conversation, message_params).perform
    end
    
    # Notify the frontend about the update
    ActionCableBroadcastJob.perform_later(
      conversation.account_id,
      'conversation.updated',
      conversation.push_event_data.merge(
        status: conversation.status
      )
    )
  end
end