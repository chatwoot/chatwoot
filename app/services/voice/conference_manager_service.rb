module Voice
  class ConferenceManagerService
    pattr_initialize [:conversation!, :event!, :call_sid!, :conference_sid, :participant_sid, :participant_label]

    def process
      # Process the conference event
      case event
      when 'conference-start'
        handle_conference_start
      when 'conference-end'
        handle_conference_end
      when 'participant-join'
        handle_participant_join
      when 'participant-leave'
        handle_participant_leave
      end

      # Create activity message for the event
      create_activity_message

      # Save conversation changes
      conversation.save!
    end

    private

    def message_service
      @message_service ||= Voice::MessageUpdateService.new(
        conversation: conversation,
        call_sid: call_sid
      )
    end

    def handle_conference_start
      conversation.additional_attributes ||= {}
      conversation.additional_attributes['conference_status'] = 'started'
      conversation.additional_attributes['conference_started_at'] = Time.now.to_i
      
      # Log conference start
      Rails.logger.info("🎧 CONFERENCE STARTED: conference_sid=#{conference_sid}")
      
      # Update call status to ringing if not already in a more advanced state
      current_status = conversation.additional_attributes['call_status']
      Rails.logger.info("📞 CURRENT CALL STATUS: '#{current_status}'")
      
      if !%w[active in-progress completed].include?(current_status)
        Rails.logger.info("📞 UPDATING CALL TO RINGING ON CONFERENCE START")
        message_service.update_call_status('ringing')
        message_service.update_voice_call_status('ringing')
        
        # Ensure we have metadata for debugging
        conversation.additional_attributes['meta'] ||= {}
        conversation.additional_attributes['meta']['ringing_at'] = Time.now.to_i
        conversation.additional_attributes['meta']['conference_started_at'] = Time.now.to_i
        conversation.save!
      end
    end

    def handle_conference_end
      conversation.additional_attributes ||= {}
      conversation.additional_attributes['conference_status'] = 'ended'
      conversation.additional_attributes['conference_ended_at'] = Time.now.to_i
      
      # Log conference end
      Rails.logger.info("🎧 CONFERENCE ENDED: conference_sid=#{conference_sid}")
      
      # Determine the final call status based on the current state
      current_status = conversation.additional_attributes['call_status']
      Rails.logger.info("📞 CURRENT CALL STATUS AT CONFERENCE END: '#{current_status}'")
      
      if current_status == 'active' || current_status == 'in-progress'
        # Call was active, mark as completed
        duration = nil
        if conversation.additional_attributes['call_started_at']
          duration = Time.now.to_i - conversation.additional_attributes['call_started_at'].to_i
          Rails.logger.info("⏱️ CALCULATED CALL DURATION: #{duration} seconds")
        end
        
        Rails.logger.info("📞 MARKING ACTIVE CALL AS COMPLETED")
        message_service.update_call_status('completed', duration)
        message_service.update_voice_call_status('ended', duration)
      elsif current_status == 'ringing'
        # Call never connected, mark as missed
        Rails.logger.info("📞 MARKING RINGING CALL AS MISSED")
        message_service.update_call_status('missed')
        message_service.update_voice_call_status('missed')
      else
        # Default to completed status
        Rails.logger.info("📞 MARKING CALL AS COMPLETED (DEFAULT)")
        message_service.update_call_status('completed')
        message_service.update_voice_call_status('ended')
      end
      
      # Ensure metadata is updated
      conversation.additional_attributes['meta'] ||= {}
      conversation.additional_attributes['meta']['conference_ended_at'] = Time.now.to_i
      
      # Force update UI to show the change
      ActionCable.server.broadcast(
        "#{conversation.account_id}_#{conversation.inbox_id}",
        {
          event_name: 'call_status_changed',
          data: {
            call_sid: call_sid,
            status: conversation.additional_attributes['call_status'],
            conversation_id: conversation.id,
            force_refresh: true
          }
        }
      )
      
      Rails.logger.info("📢 BROADCAST: Sent conference end notification")
    end

    def handle_participant_join
      # Track the participant
      update_participant_info('joined')
      
      # Log the participant joining
      Rails.logger.info("👥 PARTICIPANT JOINED: #{participant_label || 'unknown'} (#{participant_sid})")
      
      # Store participant join time based on type
      if participant_label&.start_with?('agent')
        conversation.additional_attributes['agent_joined_at'] = Time.now.to_i
        Rails.logger.info("👤 AGENT JOINED AT: #{Time.now.to_i}")
        
        # If call is ringing when agent joins, mark as active
        if conversation.additional_attributes['call_status'] == 'ringing'
          Rails.logger.info("📞 UPDATING RINGING CALL TO ACTIVE (agent joined)")
          message_service.update_call_status('active')
          message_service.update_voice_call_status('active')
        end
      elsif participant_label&.start_with?('caller')
        conversation.additional_attributes['caller_joined_at'] = Time.now.to_i
        Rails.logger.info("👤 CALLER JOINED AT: #{Time.now.to_i}")
        
        # For outbound calls
        if conversation.additional_attributes['call_direction'] == 'outbound'
          # Mark call as active as soon as caller joins an outbound call
          # This ensures the call doesn't get stuck in ringing
          if conversation.additional_attributes['call_status'] == 'ringing'
            Rails.logger.info("📞 UPDATING RINGING OUTBOUND CALL TO ACTIVE (caller joined)")
            message_service.update_call_status('active')
            message_service.update_voice_call_status('active')
          end
        end
      else
        # Generic participant (no label)
        Rails.logger.info("👤 GENERIC PARTICIPANT JOINED")
        
        # If we're stuck in ringing, try to move forward
        if conversation.additional_attributes['call_status'] == 'ringing' && 
           (Time.now.to_i - conversation.additional_attributes.dig('meta', 'ringing_at').to_i > 10)
          Rails.logger.info("📞 UPDATING LONG-RINGING CALL TO ACTIVE (participant joined)")
          message_service.update_call_status('active')
          message_service.update_voice_call_status('active')
        end
      end
      
      # Check if both caller and agent have joined
      if conversation.additional_attributes['agent_joined_at'] && 
         conversation.additional_attributes['caller_joined_at']
        # Ensure call is marked as active when both parties are present
        if conversation.additional_attributes['call_status'] != 'active'
          Rails.logger.info("📞 UPDATING CALL STATUS TO ACTIVE (both parties present)")
          message_service.update_call_status('active')
          message_service.update_voice_call_status('active')
        end
      end
    end

    def handle_participant_leave
      # Update participant tracking
      update_participant_info('left')
      
      # Record leave time based on participant type
      if participant_label&.start_with?('agent')
        conversation.additional_attributes['agent_left_at'] = Time.now.to_i
      elsif participant_label&.start_with?('caller')
        conversation.additional_attributes['caller_left_at'] = Time.now.to_i
      end
      
      # Handle caller leaving during ringing phase
      if participant_label&.start_with?('caller') && 
         conversation.additional_attributes['call_status'] == 'ringing'
        
        # Check if any agent has joined
        has_agent_joined = participant_has_joined?('agent')
        
        unless has_agent_joined
          message_service.update_call_status('missed')
          message_service.update_voice_call_status('missed')
        end
      end
      
      # Handle case where all participants have left but conference is still active
      if all_participants_left? && 
         conversation.additional_attributes['conference_status'] != 'ended' &&
         conversation.additional_attributes['call_status'] == 'active'
        
        # Calculate duration if we can
        duration = nil
        if conversation.additional_attributes['call_started_at']
          duration = Time.now.to_i - conversation.additional_attributes['call_started_at'].to_i
        end
        
        message_service.update_call_status('completed', duration)
        message_service.update_voice_call_status('ended', duration)
      end
    end

    def update_participant_info(status)
      # Initialize participants tracking
      conversation.additional_attributes ||= {}
      conversation.additional_attributes['participants'] ||= {}
      
      # Determine participant type from label
      participant_type = participant_label&.start_with?('agent') ? 'agent' : 'caller'
      
      if status == 'joined'
        # Add or update participant
        conversation.additional_attributes['participants'][participant_sid] = {
          'joined_at' => Time.now.to_i,
          'type' => participant_type,
          'call_sid' => call_sid,
          'status' => 'joined'
        }
      elsif status == 'left' && conversation.additional_attributes['participants'].key?(participant_sid)
        # Update existing participant
        conversation.additional_attributes['participants'][participant_sid]['status'] = 'left'
        conversation.additional_attributes['participants'][participant_sid]['left_at'] = Time.now.to_i
      end
    end

    def participant_has_joined?(type)
      participants = conversation.additional_attributes['participants'] || {}
      
      if participants.is_a?(Hash)
        return participants.values.any? { |p| p['type'] == type && p['status'] == 'joined' }
      end
      
      false
    end

    def all_participants_left?
      participants = conversation.additional_attributes['participants'] || {}
      
      if participants.is_a?(Hash)
        return !participants.values.any? { |p| p['status'] == 'joined' }
      end
      
      true # Default to true if no participants structure exists
    end

    def create_activity_message
      content = case event
                when 'conference-start'
                  'Conference started'
                when 'conference-end'
                  'Conference ended'
                when 'participant-join'
                  participant_type = participant_label&.start_with?('agent') ? 'Agent' : 'Caller'
                  "#{participant_type} joined the call"
                when 'participant-leave'
                  participant_type = participant_label&.start_with?('agent') ? 'Agent' : 'Caller'
                  "#{participant_type} left the call"
                else
                  "Call event: #{event}"
                end
      
      message_service.create_activity_message(content)
    end
  end
end