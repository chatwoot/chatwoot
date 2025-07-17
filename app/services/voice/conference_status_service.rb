module Voice
  class ConferenceStatusService
    pattr_initialize [:account!, :params!]

    def process
      info = status_info
      conversation = find_conversation(info)
      
      return unless conversation
      
      # Handle outbound call notification
      if info[:event] == 'participant-join' && 
         conversation.additional_attributes['call_direction'] == 'outbound' && 
         info[:participant_label]&.start_with?('caller-')
        broadcast_agent_notification(conversation, info)
      end
      
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
      {
        call_sid: params['CallSid'],
        conference_sid: params['ConferenceSid'],
        event: normalize_event_name(params['StatusCallbackEvent']),
        participant_sid: params['ParticipantSid'],
        participant_label: params['ParticipantLabel']
      }
    end

    private
    
    def normalize_event_name(raw_event)
      return 'unknown' unless raw_event.present?
      
      case raw_event.downcase.gsub(/\s+/, '')
      when 'participant-join', 'participantjoin', 'participantjoined'
        'participant-join'
      when 'participant-leave', 'participantleave', 'participantleft'
        'participant-leave'
      when 'conference-start', 'conferencestart', 'conferencestarted'
        'conference-start'
      when 'conference-end', 'conferenceend', 'conferenceended'
        'conference-end'
      else
        raw_event.downcase.gsub(/\s+/, '-')
      end
    end

    def find_conversation(info)
      # Try by conference_sid first
      if info[:conference_sid].present?
        conversation = account.conversations.where("additional_attributes->>'conference_sid' = ?", info[:conference_sid]).first
        return conversation if conversation
        
        # Try pattern matching for our format
        if info[:conference_sid].start_with?('conf_account_')
          match = info[:conference_sid].match(/conf_account_\d+_conv_(\d+)/)
          if match && match[1].present?
            return account.conversations.find_by(display_id: match[1])
          end
        end
      end
      
      # Try by call_sid
      if info[:call_sid].present?
        return account.conversations.where("additional_attributes->>'call_sid' = ?", info[:call_sid]).first
      end
      
      nil
    end

    def broadcast_agent_notification(conversation, info)
      # This method is no longer needed since conversation.created events
      # will handle incoming call notifications
    end
  end
end