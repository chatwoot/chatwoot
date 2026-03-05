class Voice::Conference::Manager
  pattr_initialize [:conversation!, :event!, :call_sid!, :participant_label]

  def process
    case event
    when 'start'
      ensure_conference_sid!
      mark_ringing!
    when 'join'
      mark_in_progress! if agent_participant?
    when 'leave'
      handle_leave!
    when 'end'
      finalize_conference!
    end
  end

  private

  def status_manager
    @status_manager ||= Voice::CallStatus::Manager.new(
      conversation: conversation,
      call_sid: call_sid
    )
  end

  def ensure_conference_sid!
    attrs = conversation.additional_attributes || {}
    return if attrs['conference_sid'].present?

    attrs['conference_sid'] = Voice::Conference::Name.for(conversation)
    conversation.update!(additional_attributes: attrs)
  end

  def mark_ringing!
    return if current_status

    status_manager.process_status_update('ringing')
  end

  def mark_in_progress!
    status_manager.process_status_update('in-progress', timestamp: current_timestamp)
  end

  def handle_leave!
    case current_status
    when 'ringing'
      status_manager.process_status_update('no-answer', timestamp: current_timestamp)
    when 'in-progress'
      status_manager.process_status_update('completed', timestamp: current_timestamp)
    end
  end

  def finalize_conference!
    return if %w[completed no-answer failed].include?(current_status)

    status_manager.process_status_update('completed', timestamp: current_timestamp)
  end

  def current_status
    conversation.additional_attributes&.dig('call_status')
  end

  def agent_participant?
    participant_label.to_s.start_with?('agent')
  end

  def current_timestamp
    Time.zone.now.to_i
  end
end
