module Voice
  class ConferenceManagerService
    pattr_initialize [:conversation!, :event!, :call_sid!, :participant_label]

    def process
      case event
      when 'start'
        handle_conference_start
      when 'end'
        handle_conference_end
      when 'join'
        handle_participant_join
      when 'leave'
        handle_participant_leave
      end

      conversation.save!
    end

    private

    def call_status_manager
      @call_status_manager ||= Voice::CallStatus::Manager.new(
        conversation: conversation,
        call_sid: call_sid,
        provider: :twilio
      )
    end

  def handle_conference_start
      current_status = conversation.additional_attributes['call_status']
      return if %w[in-progress completed].include?(current_status)

      call_status_manager.process_status_update('ringing')
  end

  def handle_conference_end
      current_status = conversation.additional_attributes['call_status']

      if current_status == 'in-progress'
        call_status_manager.process_status_update('completed')
      elsif current_status == 'ringing'
        call_status_manager.process_status_update('no-answer')
      else
        call_status_manager.process_status_update('completed')
      end
  end

    def handle_participant_join
      if agent_participant?
        handle_agent_join
      elsif caller_participant?
        handle_caller_join
      end
    end

    def handle_participant_leave
      if caller_participant? && call_in_progress?
        call_status_manager.process_status_update('completed')
      elsif caller_participant? && ringing_call? && !agent_joined?
        call_status_manager.process_status_update('no-answer')
      end
    end

  def handle_agent_join
    conversation.additional_attributes['agent_joined_at'] = Time.now.to_i

    # Do not move to in_progress if call already ended
    return if conversation.additional_attributes['call_ended_at'].present?
    return unless ringing_call?

    call_status_manager.process_status_update('in-progress')
  end

  def handle_caller_join
    conversation.additional_attributes['caller_joined_at'] = Time.now.to_i

    # Do not move to in_progress if call already ended
    return if conversation.additional_attributes['call_ended_at'].present?
    return unless outbound_call? && ringing_call?

    call_status_manager.process_status_update('in-progress')
  end

    def agent_participant?
      participant_label&.start_with?('agent')
    end

    def caller_participant?
      participant_label&.start_with?('caller')
    end

    def outbound_call?
      conversation.additional_attributes['call_direction'] == 'outbound'
    end

    def ringing_call?
      conversation.additional_attributes['call_status'] == 'ringing'
    end

    def call_in_progress?
      conversation.additional_attributes['call_status'] == 'in-progress'
    end

    def agent_joined?
      conversation.additional_attributes['agent_joined_at'].present?
    end
  end
end
