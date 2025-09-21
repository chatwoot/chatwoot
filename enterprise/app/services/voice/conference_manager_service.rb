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
        handle_any_participant_join
      when 'leave'
        handle_any_participant_leave
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

    # Treat any participant join as moving to in-progress from ringing
    def handle_any_participant_join
      return if conversation.additional_attributes['call_ended_at'].present?
      return unless conversation.additional_attributes['call_status'] == 'ringing'
      return unless participant_label.to_s.start_with?('agent')

      call_status_manager.process_status_update('in-progress')
    end

    # If a participant leaves while in-progress, mark completed; if still ringing, mark no-answer
    def handle_any_participant_leave
      status = conversation.additional_attributes['call_status']
      if status == 'in-progress'
        call_status_manager.process_status_update('completed')
      elsif status == 'ringing'
        call_status_manager.process_status_update('no-answer')
      end

      # Proactively end the conference when any participant leaves
      Voice::ConferenceEndService.new(conversation: conversation).perform
    end
  end
end
