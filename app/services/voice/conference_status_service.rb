module Voice
  # Handles Twilio conference status webhook callbacks
  # Normalizes events, finds the relevant conversation,
  # and delegates processing to ConferenceManagerService
  class ConferenceStatusService
    pattr_initialize [:account!, :params!]
    
    # Map of Twilio event names to our normalized format
    EVENT_MAPPING = {
      # Join events
      'participant-join' => 'participant-join',
      'participantjoin' => 'participant-join',
      'participantjoined' => 'participant-join',
      'participant_join' => 'participant-join',
      
      # Leave events
      'participant-leave' => 'participant-leave',
      'participantleave' => 'participant-leave',
      'participantleft' => 'participant-leave',
      'participant_leave' => 'participant-leave',
      
      # Conference start events
      'conference-start' => 'conference-start',
      'conferencestart' => 'conference-start',
      'conferencestarted' => 'conference-start',
      'conference_start' => 'conference-start',
      
      # Conference end events
      'conference-end' => 'conference-end',
      'conferenceend' => 'conference-end',
      'conferenceended' => 'conference-end',
      'conference_end' => 'conference-end'
    }.freeze

    def process
      
      # Extract status info and find conversation
      info = status_info
      conversation = find_conversation(info)
      
      return unless conversation
      
      # Update participant tracking info
      update_participant_info(conversation, info)
      
      # Process the event with the conference manager
      
      Voice::ConferenceManagerService.new(
        conversation: conversation,
        event: info[:event],
        call_sid: info[:call_sid],
        conference_sid: info[:conference_sid],
        participant_sid: info[:participant_sid],
        participant_label: info[:participant_label]
      ).process
    end

    def status_info
      # Get and normalize the event name
      raw_event = params['StatusCallbackEvent']
      normalized_event = normalize_event_name(raw_event)
      
      {
        call_sid: params['CallSid'],
        conference_sid: params['ConferenceSid'],
        event: normalized_event,
        participant_sid: params['ParticipantSid'],
        participant_label: params['ParticipantLabel']
      }
    end

    private
    
    def normalize_event_name(raw_event)
      return 'unknown' unless raw_event.present?
      
      event_text = raw_event.downcase.gsub(/\s+/, '')
      
      # Look up in mapping
      EVENT_MAPPING[event_text] || event_text.gsub(/([a-z\d])([A-Z])/, '\1-\2').gsub('_', '-').gsub(/--+/, '-')
    end

    def find_conversation(info)
      # Try by conference_sid first
      if info[:conference_sid].present?
        conversation = find_by_conference_sid(info[:conference_sid])
        return conversation if conversation
      end
      
      # Try by call_sid if available
      if info[:call_sid].present?
        conversation = account.conversations.where("additional_attributes->>'call_sid' = ?", info[:call_sid]).first
        return conversation if conversation
      end
      
      nil
    end
    
    def find_by_conference_sid(conference_sid)
      # Direct match by conference_sid
      conversation = account.conversations.where("additional_attributes->>'conference_sid' = ?", conference_sid).first
      return conversation if conversation
      
      # Try pattern matching if it looks like our format
      if conference_sid.start_with?('conf_account_')
        conference_parts = conference_sid.match(/conf_account_\d+_conv_(\d+)/)
        if conference_parts && conference_parts[1].present?
          conversation_display_id = conference_parts[1]
          return account.conversations.find_by(display_id: conversation_display_id)
        end
      end
      
      nil
    end

    def update_participant_info(conversation, info)
      # Skip if no participant info
      return unless info[:participant_sid].present?
      
      # Initialize tracking
      conversation.additional_attributes ||= {}
      conversation.additional_attributes['participants'] ||= {}
      
      participant_sid = info[:participant_sid]
      
      # Update based on event type
      case info[:event]
      when 'participant-join'
        track_participant_join(conversation, participant_sid, info)
      when 'participant-leave'
        track_participant_leave(conversation, participant_sid)
      end
      
      conversation.save!
    end
    
    def track_participant_join(conversation, participant_sid, info)
      # Add participant
      conversation.additional_attributes['participants'][participant_sid] = {
        'joined_at' => Time.now.to_i,
        'type' => info[:participant_label]&.start_with?('agent') ? 'agent' : 'caller',
        'call_sid' => info[:call_sid],
        'status' => 'joined'
      }
      
      # Handle outbound calls where caller has joined
      if conversation.additional_attributes['call_direction'] == 'outbound' && 
          info[:participant_label]&.start_with?('caller-')
        conversation.additional_attributes['requires_agent_join'] = true
        broadcast_agent_notification(conversation, info)
      end
    end
    
    def track_participant_leave(conversation, participant_sid)
      if conversation.additional_attributes['participants'].key?(participant_sid)
        conversation.additional_attributes['participants'][participant_sid]['status'] = 'left'
        conversation.additional_attributes['participants'][participant_sid]['left_at'] = Time.now.to_i
      end
    end

    def broadcast_agent_notification(conversation, info)
      contact = conversation.contact
      inbox = conversation.inbox
      
      # Get contact name, ensuring we have a valid value
      contact_name_value = contact&.name.presence || contact&.phone_number || 'Outbound Call'
      
      # Create the data payload
      broadcast_data = {
        call_sid: info[:call_sid],
        conversation_id: conversation.display_id,
        inbox_id: conversation.inbox_id,
        inbox_name: conversation.inbox.name,
        inbox_avatar_url: inbox.avatar_url, # Include inbox avatar
        inbox_phone_number: inbox.channel.phone_number, # Include inbox phone number
        contact_name: contact_name_value,
        contact_id: contact&.id,
        is_outbound: true,
        account_id: account.id,
        conference_sid: info[:conference_sid],
        phone_number: contact&.phone_number, # Include phone number for display in UI
        avatar_url: contact&.avatar_url, # Include avatar URL for display in UI
        call_direction: 'outbound' # Add call direction for context
      }
      
      
      ActionCable.server.broadcast(
        "account_#{account.id}",
        {
          event: 'incoming_call',
          data: broadcast_data
        }
      )
    end
  end
end