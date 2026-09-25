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
    return unless user_id

    claim_for_user!(user_id)
    status_manager.process_status_update('in_progress', timestamp: now)
    return unless call.accepted_by_agent_id == user_id && mark_accepted_broadcast!

    call.broadcast_voice_call_event(:accepted, accepted_by_agent_id: call.accepted_by_agent_id)
  end

  # First-join wins; later joins by other agents are silently ignored so the
  # webhook doesn't stomp the original assignee. User-facing rejection happens
  # at the API layer.
  def claim_for_user!(user_id)
    claimed = false
    call.with_lock do
      next if call.terminal? || (call.accepted_by_agent_id.present? && call.accepted_by_agent_id != user_id)

      call.update!(accepted_by_agent_id: user_id) if call.accepted_by_agent_id != user_id
      claimed = true
    end

    auto_assign_conversation!(user_id) if claimed
  end

  # Exactly-once gate for the accepted broadcast, tracked separately from the claim: the
  # claim can already be set before this webhook runs (mark_agent_joined on POST /conference,
  # or OutboundCallBuilder at call creation), and call.status can already be in_progress via
  # the contact's own "answered" callback — neither is a reliable "already broadcast" signal.
  def mark_accepted_broadcast!
    first_time = false
    call.with_lock do
      next if call.terminal? || call.accepted_broadcast_at.present?

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

  # Parses agent user_id from participant_label. Only returns an id when the
  # label's embedded account id matches the call's account — protects against
  # a spoofed/cross-account label attaching a foreign user to the call.
  def extract_user_id
    match = participant_label.to_s.match(AGENT_LABEL_PATTERN)
    return unless match
    return unless match[2].to_i == call.account_id

    match[1].to_i
  end

  # An agent leg leaving a live call ends it only when no other agent remains; the contact
  # is hung up first and the call completes after. A phone can drop its leg without ever
  # sending DELETE conference: the app was killed, the network went, or the OS ended the call.
  def handle_leave!
    case call.status
    when 'ringing'
      status_manager.process_status_update('no_answer', timestamp: now)
    when 'in_progress'
      return if agent_participant? && other_agents_remain?

      hang_up_contact! if agent_participant?
      status_manager.process_status_update('completed', timestamp: now)
    end
  end

  # When Twilio cannot say who is left, the call stays live and a job repeats the check:
  # the contact does not leave a conference on their own, so an unknown answer cannot be
  # allowed to stand
  def other_agents_remain?
    conference_service.agents_remain?(leaving_label: participant_label)
  rescue StandardError => e
    Rails.logger.error("[VOICE] call #{call.id}: could not list conference participants: #{e.class}: #{e.message}")
    Voice::EndConferenceJob.perform_later(call.id, leaving_label: participant_label)
    true
  end

  # The conference must end even if Twilio is briefly unreachable, so a failed attempt is retried by a job
  def hang_up_contact!
    conference_service.end_conference
  rescue StandardError => e
    Rails.logger.error("[VOICE] call #{call.id}: could not end conference after agent leave: #{e.class}: #{e.message}")
    Voice::EndConferenceJob.perform_later(call.id)
  end

  def conference_service
    @conference_service ||= Voice::Provider::Twilio::ConferenceService.new(call: call)
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
