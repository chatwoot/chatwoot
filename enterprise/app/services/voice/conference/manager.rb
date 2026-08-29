class Voice::Conference::Manager
  pattr_initialize [:call!, :event!, :participant_label, :participant_call_sid, :participant_timestamp]

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
    return if defer_join_if_termination_pending!
    return if claim_for_user!(user_id) == :deferred
    return unless call.accepted_by_agent_id == user_id && mark_accepted_broadcast!

    call.broadcast_voice_call_event(:accepted, accepted_by_agent_id: call.accepted_by_agent_id)
  end

  def defer_join_if_termination_pending!
    deferred = false
    call.with_lock do
      Voice::CallTerminationGuard.clear_stale!(call)
      next unless Voice::CallTerminationGuard.active?(call)

      persist_pending_join_locked!
      deferred = true
    end
    schedule_join_reconciliation if deferred
    deferred
  end

  def claim_for_user!(user_id)
    claimed = false
    deferred = false
    call.with_lock do
      if termination_pending_locked?
        persist_pending_join_locked!
        deferred = true
        next
      end
      next unless claimable_by?(user_id)

      call.update!(accepted_by_agent_id: user_id) if call.accepted_by_agent_id != user_id
      status_manager.process_status_update('in_progress', timestamp: join_timestamp)
      claimed = true
    end

    if deferred
      schedule_join_reconciliation
      return :deferred
    end

    auto_assign_conversation!(user_id) if claimed
    claimed
  end

  def claimable_by?(user_id)
    return false if call.terminal?

    call.accepted_by_agent_id.blank? || call.accepted_by_agent_id == user_id
  end

  def mark_accepted_broadcast!
    first_time = false
    deferred = false
    call.with_lock do
      if termination_pending_locked?
        persist_pending_join_locked!
        deferred = true
        next
      end
      next if call.terminal? || call.accepted_broadcast_at.present?

      call.update!(accepted_broadcast_at: now)
      first_time = true
    end
    schedule_join_reconciliation if deferred
    first_time
  end

  def persist_pending_join_locked!
    Voice::CallTerminationGuard.persist_pending_join!(
      call,
      participant_label: participant_label,
      participant_call_sid: participant_call_sid,
      timestamp: join_timestamp
    )
  end

  def schedule_join_reconciliation
    Voice::ReconcileSuppressedTerminationJob
      .set(wait: Voice::CallTerminationGuard::STALE_AFTER + 5.seconds)
      .perform_later(call.id)
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

  def join_timestamp
    participant_timestamp.presence || now
  end

  def now
    Time.zone.now.to_i
  end
end
