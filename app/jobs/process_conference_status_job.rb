class ProcessConferenceStatusJob < ApplicationJob
  queue_as :default

  def perform(options = {})
    # Extract parameters from options
    conversation_id = options[:conversation_id]
    event = options[:event]
    call_sid = options[:call_sid]
    conference_sid = options[:conference_sid]
    account_id = options[:account_id]
    participant_sid = options[:participant_sid]
    participant_label = options[:participant_label]
    call_sid_ending_with = options[:call_sid_ending_with]
    audio_level = options[:audio_level]
    
    # Set the current account (required for proper routing)
    Current.account = Account.find(account_id)
    
    # Find the conversation
    conversation = Current.account.conversations.find_by(id: conversation_id)
    return unless conversation
    
    # Update conversation with conference info
    conversation.additional_attributes ||= {}
    conversation.additional_attributes['conference_sid'] = conference_sid
    
    # Store more detailed audio diagnostics for speak events
    if event == 'participant-speak'
      conversation.additional_attributes['last_speak_event'] = {
        participant_sid: participant_sid,
        timestamp: Time.now.to_i,
        audio_level: audio_level || 'unknown'
      }
    end

    # Process the event
    case event
    when 'conference-start'
      conversation.additional_attributes['conference_status'] = 'started'
      activity_message = 'Conference started'
    when 'conference-end'
      conversation.additional_attributes['conference_status'] = 'ended'
      conversation.additional_attributes['call_status'] = 'completed'
      conversation.additional_attributes['call_ended_at'] = Time.now.to_i
      conversation.status = :resolved
      activity_message = 'Conference ended'
    when 'participant-join'
      # Track participant type for debugging
      participant_type = participant_label || (call_sid_ending_with || '').start_with?('agent') ? 'agent' : 'caller'
      activity_message = "#{participant_type.capitalize} joined the call"
      
      # Track all participants for audio diagnostics
      conversation.additional_attributes['participants'] ||= {}
      conversation.additional_attributes['participants'][participant_sid] = {
        joined_at: Time.now.to_i,
        type: participant_type,
        call_sid: call_sid,
        status: 'joined'
      }
    when 'participant-leave'
      # Update participant status
      if conversation.additional_attributes['participants']&.key?(participant_sid)
        participant_type = conversation.additional_attributes['participants'][participant_sid]['type'] || 'Participant'
        activity_message = "#{participant_type.capitalize} left the call"
        
        # Mark participant as left
        conversation.additional_attributes['participants'][participant_sid]['status'] = 'left'
        conversation.additional_attributes['participants'][participant_sid]['left_at'] = Time.now.to_i
      else
        activity_message = 'Participant left the call'
      end
    when 'participant-speak'
      # This is critical for diagnosing audio issues
      if conversation.additional_attributes['participants']&.key?(participant_sid)
        participant_type = conversation.additional_attributes['participants'][participant_sid]['type'] || 'Participant'
        activity_message = "#{participant_type} speaking detected"
        
        # Track speaking events
        participant = conversation.additional_attributes['participants'][participant_sid]
        participant['speak_events'] ||= []
        participant['speak_events'] << Time.now.to_i
        
        # Only keep the last 5 events to avoid bloating the database
        participant['speak_events'] = participant['speak_events'].last(5) if participant['speak_events'].size > 5
        
        conversation.additional_attributes['participants'][participant_sid] = participant
      else
        activity_message = 'Speech detected'
      end
    else
      activity_message = "Call event: #{event}"
    end

    # Save conversation with enhanced tracking
    begin
      conversation.save!
      Rails.logger.info("✅ Conference status updated: #{event} for conversation_id=#{conversation.id}")
    rescue => e
      Rails.logger.error("❌ Failed to save conversation: #{e.message}")
    end

    # Create activity message with enhanced attributes
    begin
      Messages::MessageBuilder.new(
        nil,
        conversation,
        {
          content: activity_message,
          message_type: :activity,
          additional_attributes: {
            call_sid: call_sid,
            event_type: event,
            conference_sid: conference_sid,
            timestamp: Time.now.to_i,
            participant_sid: participant_sid,
            audio_level: audio_level
          }
        }
      ).perform
    rescue => e
      Rails.logger.error("❌ Failed to create activity message: #{e.message}")
    end

    # Broadcast call status updates on account-level channel
    begin
      # Include account_id in the data to help with validation
      data_with_account = {
        call_sid: call_sid,
        status: conversation.additional_attributes['call_status'] || 'in-progress',
        conversation_id: conversation.id,
        event: event,
        account_id: conversation.account_id
      }
      
      ActionCable.server.broadcast(
        "account_#{conversation.account_id}",
        {
          event: 'call_status_changed',
          data: data_with_account
        }
      )
    rescue => e
      Rails.logger.error("❌ Failed to broadcast call status: #{e.message}")
    end
  end
end