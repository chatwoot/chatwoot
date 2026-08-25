class Voice::Conference::Manager
  pattr_initialize [:call!, :event!, :participant_label, :participant_call_sid]

  AGENT_LABEL_PATTERN = /\Aagent-(\d+)-account-(\d+)\z/

  def process
    case event
    when 'start'
      mark_ringing!
    when 'join'
      join_agent! if agent_participant?
    when 'leave'
      handle_leave!
    when 'end'
      finalize!
    end
  end

  private

  def status_manager
    @status_manager ||= Voice::CallStatus::Manager.new(call: call)
  end

  def mark_ringing!
    return unless call.status == 'ringing'

    status_manager.process_status_update('ringing')
  end

  def join_agent!
    user_id = extract_user_id
    return unless user_id
    return if termination_pending?

    claim_for_user!(user_id)
    status_manager.process_status_update('in_progress', timestamp: now)
    return unless call.accepted_by_agent_id == user_id && mark_accepted_broadcast!

    call.broadcast_voice_call_event(:accepted, accepted_by_agent_id: call.accepted_by_agent_id)
  end

  def claim_for_user!(user_id)
    claimed = false
    call.with_lock do
      next if call.terminal? || termination_pending_locked?
      next if call.accepted_by_agent_id.present? && call.accepted_by_agent_id != user_id

      call.update!(accepted_by_agent_id: user_id) if call.accepted_by_agent_id != user_id
      claimed = true
    end

    auto_assign_conversation!(user_id) if claimed
  end

  def mark_accepted_broadcast!
    first_time = false
    call.with_lock do
      next if call.terminal? || termination_pending_locked? || call.accepted_broadcast_at.present?

      call.update!(accepted_broadcast_at: now)
      first_time = true
    end
    first_time
  end

  def auto_assign_conversation!(user_id)
    conversation = call.conversation
    return if conversation.assigned_entity.present?

    Conversations::AssignmentService.new(conversation: conversation, assignee_id: user_id).perform
  end

  def extract_user_id
    match = participant_label.to_s.match(AGENT_LABEL_PATTERN)
    return unless match
    return unless match[2].to_i == call.account_id

    match[1].to_i
  end

  def handle_leave!
    return if consume_deliberate_agent_disconnect?

    case call.status
    when 'ringing'
      status_manager.process_status_update('no_answer', timestamp: now)
    when 'in_progress'
      status_manager.process_status_update('completed', timestamp: now)
    end
  end

  def finalize!
    return if Call::TERMINAL_STATUSES.include?(call.status)

    status_manager.process_status_update('completed', timestamp: now)
  end

  def termination_pending?
    call.with_lock { termination_pending_locked? }
  end

  def termination_pending_locked?
    Voice::CallTerminationGuard.clear_stale!(call)
    Voice::CallTerminationGuard.active?(call)
  end

  def consume_deliberate_agent_disconnect?
    return false unless agent_participant?

    call.with_lock do
      Voice::CallTerminationGuard.consume_local_disconnect!(call, participant_call_sid)
    end
  end

  def agent_participant?
    participant_label.to_s.start_with?('agent-')
  end

  def now
    Time.zone.now.to_i
  end
end
