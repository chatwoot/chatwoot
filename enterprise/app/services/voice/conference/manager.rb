class Voice::Conference::Manager
  pattr_initialize [:call!, :event!, :participant_label]

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
    # Guard against delayed conference-start retries rolling a progressed call back to ringing.
    return unless call.status == 'ringing'

    status_manager.process_status_update('ringing')
  end

  def join_agent!
    user_id = extract_user_id
    claim_for_user!(user_id) if user_id
    status_manager.process_status_update('in_progress', timestamp: now)
  end

  # First-join wins; later joins by other agents are silently ignored so the
  # webhook doesn't stomp the original assignee. User-facing rejection happens
  # at the API layer.
  def claim_for_user!(user_id)
    claimed = false
    call.with_lock do
      next if call.accepted_by_agent_id.present? && call.accepted_by_agent_id != user_id

      call.update!(accepted_by_agent_id: user_id) if call.accepted_by_agent_id != user_id
      claimed = true
    end

    auto_assign_conversation!(user_id) if claimed
  end

  def auto_assign_conversation!(user_id)
    conversation = call.conversation
    return if conversation.assignee_id.present?

    Conversations::AssignmentService.new(conversation: conversation, assignee_id: user_id).perform
  end

  # Parses agent user_id from participant_label. Only returns an id when the
  # label's embedded account id matches the call's account — protects against
  # a spoofed/cross-account label attaching a foreign user to the call.
  def extract_user_id
    match = participant_label.to_s.match(AGENT_LABEL_PATTERN)
    return unless match
    return unless match[2].to_i == call.account_id

    match[1].to_i
  end

  def handle_leave!
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

  def agent_participant?
    participant_label.to_s.start_with?('agent-')
  end

  def now
    Time.zone.now.to_i
  end
end
