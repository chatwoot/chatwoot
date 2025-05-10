module Voice
  # Handles conference events (start, end, participant joins and leaves)
  # Uses CallStatusManager to update call statuses, ensuring consistency
  # This service is called directly by ConferenceStatusService
  class ConferenceManagerService
    pattr_initialize [:conversation!, :event!, :call_sid!, :conference_sid, :participant_sid, :participant_label]

    # Event constants to make code more readable
    CONFERENCE_START = 'conference-start'.freeze
    CONFERENCE_END = 'conference-end'.freeze
    PARTICIPANT_JOIN = 'participant-join'.freeze
    PARTICIPANT_LEAVE = 'participant-leave'.freeze

    # Participant types
    AGENT = 'agent'.freeze
    CALLER = 'caller'.freeze

    def process
      Rails.logger.info("🎧 CONFERENCE EVENT: #{event} for conference_sid=#{conference_sid}")

      # Process the conference event
      case event
      when CONFERENCE_START
        handle_conference_start
      when CONFERENCE_END
        handle_conference_end
      when PARTICIPANT_JOIN
        handle_participant_join
      when PARTICIPANT_LEAVE
        handle_participant_leave
      else
        Rails.logger.warn("🎧 UNKNOWN CONFERENCE EVENT: #{event}")
      end

      # Save conversation changes
      conversation.save!

      # Ensure ActionCable broadcast for terminal call states (for debugging and reliability)
      if %w[conference-end participant-leave].include?(event)
        current_status = conversation.additional_attributes['call_status']
        if %w[completed ended missed busy failed no-answer canceled].include?(current_status)
          # Defensive: broadcast call_status_changed event to ensure frontend is notified
          ui_status = Voice::CallStatus::Manager.new(conversation: conversation, call_sid: call_sid, provider: :twilio).normalized_ui_status(current_status)
          Rails.logger.info("📢 [ConferenceManagerService] Forcing ActionCable broadcast: call_status_changed (call_sid=#{call_sid}, status=#{ui_status}) for conversation_id=#{conversation.display_id}")
          ActionCable.server.broadcast(
            "account_#{conversation.account_id}",
            {
              event_name: 'call_status_changed',
              data: {
                call_sid: call_sid,
                status: ui_status,
                conversation_id: conversation.display_id, 
                inbox_id: conversation.inbox_id,
                timestamp: Time.now.to_i
              }
            }
          )
        end
      end
    end

    private

    def call_status_manager
      # Use the CallStatusManager, which will determine internally if the call is outbound
      @call_status_manager ||= Voice::CallStatus::Manager.new(
        conversation: conversation,
        call_sid: call_sid,
        provider: :twilio
      )
    end

    def handle_conference_start
      # Update conference status
      update_conference_status('started')

      # Check if we need to update call status
      current_status = conversation.additional_attributes['call_status']

      # Only update to ringing if not already in a more advanced state
      return if %w[active in-progress completed].include?(current_status)

      Rails.logger.info('📞 UPDATING CALL TO RINGING ON CONFERENCE START')
      call_status_manager.process_status_update('ringing')
    end

    def handle_conference_end
      # Update conference status
      update_conference_status('ended')

      # Get current call status
      current_status = conversation.additional_attributes['call_status']

      # Determine final call status based on current state
      finalize_call_status(current_status)
    end

    def handle_participant_join
      # Track participant join
      track_participant_join

      # Handle call status updates based on who joined
      if agent_participant?
        handle_agent_join
      elsif caller_participant?
        handle_caller_join
      else
        handle_generic_participant_join
      end

      # Check if both parties are present to mark call as active
      check_both_parties_present
    end

    def handle_participant_leave
      # Track participant leave
      track_participant_leave

      # Handle missed calls when caller leaves during ringing
      check_for_missed_call

      # Check if everyone left to end conference
      check_if_everyone_left
    end

    # Helper methods for updating conference status
    def update_conference_status(status)
      conversation.additional_attributes ||= {}
      conversation.additional_attributes['conference_status'] = status
      conversation.additional_attributes["conference_#{status}_at"] = Time.now.to_i

      # Update metadata
      conversation.additional_attributes['meta'] ||= {}
      conversation.additional_attributes['meta']["conference_#{status}_at"] = Time.now.to_i

      Rails.logger.info("🎧 CONFERENCE #{status.upcase}: conference_sid=#{conference_sid}")
    end

    # Helper methods for finalizing call status
    def finalize_call_status(current_status)
      if %w[active in-progress].include?(current_status)
        # Call was active, mark as completed with duration
        complete_active_call
      elsif current_status == 'ringing'
        # Call never connected
        Rails.logger.info('📞 MARKING RINGING CALL AS MISSED')
        call_status_manager.process_status_update('missed', nil, false, 'Missed call')
      else
        # Default to completed status
        Rails.logger.info('📞 MARKING CALL AS COMPLETED (DEFAULT)')
        call_status_manager.process_status_update('completed', nil, false, 'Call ended')
      end
    end

    def complete_active_call
      # Calculate duration if possible
      duration = nil
      if conversation.additional_attributes['call_started_at']
        duration = Time.now.to_i - conversation.additional_attributes['call_started_at'].to_i
        Rails.logger.info("⏱️ CALCULATED CALL DURATION: #{duration} seconds")
      end

      Rails.logger.info('📞 MARKING ACTIVE CALL AS COMPLETED')
      call_status_manager.process_status_update('completed', duration, false, 'Call ended')
    end

    # Helper methods for participant handling
    def track_participant_join
      # Update participant tracking
      update_participant_info('joined')
      Rails.logger.info("👥 PARTICIPANT JOINED: #{participant_label || 'unknown'} (#{participant_sid})")
    end

    def track_participant_leave
      # Update participant tracking
      update_participant_info('left')
      Rails.logger.info("👥 PARTICIPANT LEFT: #{participant_label || 'unknown'} (#{participant_sid})")

      # Record leave time based on participant type
      if agent_participant?
        conversation.additional_attributes['agent_left_at'] = Time.now.to_i
      elsif caller_participant?
        conversation.additional_attributes['caller_left_at'] = Time.now.to_i
      end
    end

    # Participant type checks
    def agent_participant?
      participant_label&.start_with?(AGENT)
    end

    def caller_participant?
      participant_label&.start_with?(CALLER)
    end

    # Participant join handlers
    def handle_agent_join
      conversation.additional_attributes['agent_joined_at'] = Time.now.to_i
      Rails.logger.info("👤 AGENT JOINED AT: #{Time.now.to_i}")

      # If call is ringing when agent joins, mark as connected
      return unless conversation.additional_attributes['call_status'] == 'ringing'

      Rails.logger.info('📞 UPDATING RINGING CALL TO CONNECTED (agent joined)')
      # Always use in-progress to be consistent with status mapping
      # Pass event context to create appropriate activity message
      call_status_manager.process_status_update('in-progress', nil, true, 'Agent joined the call')
    end

    def handle_caller_join
      conversation.additional_attributes['caller_joined_at'] = Time.now.to_i
      Rails.logger.info("👤 CALLER JOINED AT: #{Time.now.to_i}")

      # For outbound calls - mark as connected when caller joins if still ringing
      return unless outbound_call? && ringing_call?

      Rails.logger.info('📞 UPDATING RINGING OUTBOUND CALL TO CONNECTED (caller joined)')
      # Always use in-progress to be consistent with status mapping
      # Only create activity message for inbound calls where caller joining is significant
      custom_message = call_status_manager.is_outbound? ? nil : 'Caller joined the call'
      call_status_manager.process_status_update('in-progress', nil, true, custom_message)
    end

    def handle_generic_participant_join
      Rails.logger.info('👤 GENERIC PARTICIPANT JOINED')

      # If we're stuck in ringing for a while, try to move forward
      return unless ringing_call? && long_ringing?

      Rails.logger.info('📞 UPDATING LONG-RINGING CALL TO CONNECTED (participant joined)')
      # Always use in-progress to be consistent with status mapping
      call_status_manager.process_status_update('in-progress', nil, true)
    end

    # Call state checks
    def outbound_call?
      conversation.additional_attributes['call_direction'] == 'outbound'
    end

    def ringing_call?
      conversation.additional_attributes['call_status'] == 'ringing'
    end

    def long_ringing?
      ringing_at = conversation.additional_attributes.dig('meta', 'ringing_at').to_i
      ringing_at > 0 && (Time.now.to_i - ringing_at > 10)
    end

    # Both parties present check
    def check_both_parties_present
      both_present = conversation.additional_attributes['agent_joined_at'] &&
                     conversation.additional_attributes['caller_joined_at']

      # Only update if not already in an active state
      return unless both_present && !%w[active in-progress].include?(conversation.additional_attributes['call_status'])

      Rails.logger.info('📞 UPDATING CALL STATUS TO CONNECTED (both parties present)')
      # Always use in-progress to be consistent with status mapping
      call_status_manager.process_status_update('in-progress', nil, true)
    end

    # Missed call check when caller leaves
    def check_for_missed_call
      return unless caller_participant? && ringing_call? && !participant_has_joined?(AGENT)

      Rails.logger.info('📞 MARKING AS MISSED (caller left during ringing, no agent joined)')
      call_status_manager.process_status_update('missed', nil, false, 'Missed call')
    end

    # Everyone left check
    def check_if_everyone_left
      call_in_progress = %w[active in-progress].include?(conversation.additional_attributes['call_status']) 
      conference_active = conversation.additional_attributes['conference_status'] != 'ended'

      # If the caller has left but the call is still active, mark it as completed
      if caller_participant? && call_in_progress
        # Calculate duration if possible
        duration = nil
        duration = Time.now.to_i - conversation.additional_attributes['call_started_at'].to_i if conversation.additional_attributes['call_started_at']
        
        Rails.logger.info('📞 MARKING CALL AS COMPLETED (caller left during active call)')
        call_status_manager.process_status_update('completed', duration, false, 'Caller left the call')
        return
      end

      # Old code path for when everyone has left
      return unless all_participants_left? && conference_active && call_in_progress

      # Calculate duration if possible
      duration = nil
      duration = Time.now.to_i - conversation.additional_attributes['call_started_at'].to_i if conversation.additional_attributes['call_started_at']

      Rails.logger.info('📞 MARKING CALL AS COMPLETED (all participants left)')
      call_status_manager.process_status_update('completed', duration, false, 'Call ended')
      # Defensive: Immediately broadcast ActionCable event for reliability
      ui_status = call_status_manager.normalized_ui_status('completed')
      Rails.logger.info("📢 [ConferenceManagerService] Broadcasting call_status_changed (call_sid=#{call_sid}, status=#{ui_status}) after all participants left for conversation_id=#{conversation.display_id}")
      ActionCable.server.broadcast(
        "account_#{conversation.account_id}",
        {
          event_name: 'call_status_changed',
          data: {
            call_sid: call_sid,
            status: ui_status,
            conversation_id: conversation.display_id, 
            inbox_id: conversation.inbox_id,
            timestamp: Time.now.to_i
          }
        }
      )
    end

    # Participant tracking methods
    def update_participant_info(status)
      # Initialize participants tracking
      conversation.additional_attributes ||= {}
      conversation.additional_attributes['participants'] ||= {}

      # Determine participant type from label
      participant_type = agent_participant? ? AGENT : CALLER

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
      return false unless participants.is_a?(Hash)

      participants.values.any? { |p| p['type'] == type && p['status'] == 'joined' }
    end

    def all_participants_left?
      participants = conversation.additional_attributes['participants'] || {}
      return true unless participants.is_a?(Hash)

      !participants.values.any? { |p| p['status'] == 'joined' }
    end

    def broadcast_call_status_changed
      ui_status = call_status_manager.normalized_ui_status('completed')
      Rails.logger.info("📢 [ConferenceManagerService] Broadcasting call_status_changed (call_sid=#{call_sid}, status=#{ui_status}) after all participants left for conversation_id=#{conversation.display_id}")
      ActionCable.server.broadcast(
        "account_#{conversation.account_id}",
        {
          event_name: 'call_status_changed',
          data: {
            call_sid: call_sid,
            status: ui_status,
            conversation_id: conversation.display_id, 
            inbox_id: conversation.inbox_id,
            timestamp: Time.now.to_i
          }
        }
      )
    end
  end
end