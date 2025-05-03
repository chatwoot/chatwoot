module Voice
  class ConferenceStatusService
    pattr_initialize [:account!, :params!]

    def process
      find_conversation
      queue_status_processing if @conversation
    end

    def status_info
      {
        call_sid: params['CallSid'],
        conference_sid: params['ConferenceSid'],
        event: params['StatusCallbackEvent'],
        participant_sid: params['ParticipantSid'],
        participant_label: params['ParticipantLabel'],
        call_sid_ending_with: params['CallSidEndingWith'],
        audio_level: params['AudioLevel']
      }
    end

    private

    def find_conversation
      @conversation = nil

      # Try finding by conference_sid
      if status_info[:conference_sid].present?
        @conversation = account.conversations
                               .where("additional_attributes->>'conference_sid' = ?", status_info[:conference_sid])
                               .first
      end

      # If not found and conference_sid looks like our format, extract conversation ID
      if @conversation.nil? && status_info[:conference_sid].present? && status_info[:conference_sid].start_with?('conf_account_')
        conference_parts = status_info[:conference_sid].match(/conf_account_\d+_conv_(\d+)/)
        if conference_parts && conference_parts[1].present?
          conversation_display_id = conference_parts[1]
          @conversation = account.conversations.find_by(display_id: conversation_display_id)
          Rails.logger.info("🎧 Found conversation by display_id=#{conversation_display_id} from conference_sid=#{status_info[:conference_sid]}")
        end
      end

      # If still not found, try by call_sid
      if @conversation.nil? && status_info[:call_sid].present?
        @conversation = account.conversations
                               .where("additional_attributes->>'call_sid' = ?", status_info[:call_sid])
                               .first
      end

      # Update participant info if conversation found
      update_participant_info if @conversation
    end

    def update_participant_info
      # Initialize or get current participants list
      @conversation.additional_attributes ||= {}
      @conversation.additional_attributes['participants'] ||= []
      
      # Check if this participant is already in the list
      existing_participant = @conversation.additional_attributes['participants'].find do |p|
        p['call_sid'] == status_info[:call_sid]
      end
      
      # Update based on event type
      if status_info[:event] == 'join'
        # Add participant if not exists
        unless existing_participant
          @conversation.additional_attributes['participants'] << {
            'call_sid' => status_info[:call_sid],
            'label' => status_info[:participant_label],
            'joined_at' => Time.now.to_i
          }
        end
      elsif status_info[:event] == 'leave'
        # Remove participant if exists
        @conversation.additional_attributes['participants'].reject! { |p| p['call_sid'] == status_info[:call_sid] }
      end
      
      # Flag outbound calls that need agent join
      if @conversation.additional_attributes['call_direction'] == 'outbound' && 
          status_info[:participant_label]&.start_with?('caller-') &&
          status_info[:event] == 'join'
        
        # This is the customer joining an outbound call - flag for agent to join immediately
        @conversation.additional_attributes['requires_agent_join'] = true
        
        # Broadcast an immediate "incoming call" notification for the agent
        broadcast_agent_join_notification
      end
      
      # Save the updated conversation
      @conversation.save!
    end

    def broadcast_agent_join_notification
      ActionCable.server.broadcast(
        "account_#{account.id}",
        {
          event: 'incoming_call',
          data: {
            call_sid: status_info[:call_sid],
            conversation_id: @conversation.id,
            inbox_id: @conversation.inbox_id,
            inbox_name: @conversation.inbox.name,
            contact_name: @conversation.contact.name || 'Outbound Call',
            contact_id: @conversation.contact_id,
            is_outbound: true,
            account_id: account.id
          }
        }
      )
    end

    def queue_status_processing
      # Process the status update directly using the service
      Voice::ConferenceStatusUpdateService.new(
        conversation: @conversation,
        event: status_info[:event],
        call_sid: status_info[:call_sid],
        conference_sid: status_info[:conference_sid],
        participant_sid: status_info[:participant_sid],
        participant_label: status_info[:participant_label]
      ).process
    end
  end
end