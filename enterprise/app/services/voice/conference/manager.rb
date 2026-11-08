class Voice::Conference::Manager
  pattr_initialize [:call!, :event!, :participant_label, :participant_call_sid, :leave_reason]

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

  def status_manager = (@status_manager ||= Voice::CallStatus::Manager.new(call: call))

  def mark_ringing!
    # Guard against delayed conference-start retries rolling a progressed call back to ringing.
    return unless call.status == 'ringing'

    status_manager.process_status_update('ringing')
  end

  def join_agent!
    user_id = extract_user_id
    return unless user_id

    return if claim_for_user!(user_id) == :gone
    return unless call.accepted_by_agent_id == user_id && mark_accepted_broadcast!

    call.broadcast_voice_call_event(:accepted, accepted_by_agent_id: call.accepted_by_agent_id)
  end

  # First-join wins; later joins by other agents are silently ignored so the
  # webhook doesn't stomp the original assignee. User-facing rejection happens
  # at the API layer.
  #
  # A join reported late for a connection that has already left changes nothing, and
  # returns :gone. The join moves the call to in progress under the same row lock, so a
  # caller's hang-up lands wholly before the join, as a missed call, or after it, as an
  # answered one.
  def claim_for_user!(user_id)
    claimed = false
    outcome = call.with_lock do
      next :gone if leg_gone?
      next if call.terminal?

      unless call.accepted_by_agent_id.present? && call.accepted_by_agent_id != user_id
        call.update!(accepted_by_agent_id: user_id) if call.accepted_by_agent_id != user_id
        call.record_agent_leg!(participant_call_sid, 'joined')
        claimed = true
      end
      status_manager.process_status_update('in_progress', timestamp: now)
    end

    auto_assign_conversation!(user_id) if claimed
    outcome
  end

  def leg_gone? = participant_call_sid.present? && call.agent_legs.dig(participant_call_sid, 'state') == 'gone'

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
    conference_service.remember_claim_assignment(user_id)
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

  # A disconnected phone may never send DELETE /conference.
  def handle_leave!
    return handle_failed_add! if failed_add?

    leave_agent_leg! if agent_participant?
    live = leave_finds_live_call?
    return end_conference! if contact_leaving_answered_call?
    return unless live
    return if agent_participant? && agent_still_on_call?

    complete_call!
  end

  # An outbound contact may still be ringing outside the conference.
  def complete_call!
    status_manager.process_status_update('completed', timestamp: now)
    end_conference!
    hang_up_contact! if call.outgoing?
  end

  def agent_still_on_call?
    looked_at = now
    return true if other_agents_remain?

    wait = conference_service.complete_unless_agent_joining(leaving_call_sid: participant_call_sid, since: looked_at)
    return false unless wait

    Voice::EndConferenceJob.set(wait: wait.seconds).perform_later(call.id, leaving_call_sid: participant_call_sid) if wait.positive?
    true
  end

  def leave_agent_leg! = call.with_lock { call.record_agent_leg!(participant_call_sid, 'gone') }

  def leave_finds_live_call?
    call.with_lock do
      next true if call.in_progress? || claimant_leaving_unjoined_call?

      status_manager.process_status_update('no_answer', timestamp: now) if call.ringing?
      false
    end
  end

  # The contact's status callback can precede its conference leave.
  def contact_leaving_answered_call? = !agent_participant? && call.terminal? && call.accepted_by_agent_id.present?

  def failed_add? = agent_participant? && leave_reason == 'participant_add_failed'

  # Failed legs never joined; replacement legs may still be connecting.
  def handle_failed_add!
    user_id = extract_user_id
    outcome = call.with_lock { failed_add_outcome(user_id) }
    return release_claim_assignment(user_id) if outcome == :release
    return end_unjoined_call! if outcome == :end

    recheck_failed_add(outcome) if outcome.is_a?(Integer)
  end

  # A conference with no agent may not have started, so its contact leg needs a separate hangup.
  def end_unjoined_call!
    end_conference!
    hang_up_contact!
  end

  def hang_up_contact!
    conference_service.terminate_call
  rescue StandardError => e
    Rails.logger.error("[VOICE] call #{call.id}: could not hang up the contact: #{e.class}: #{e.message}")
    Voice::HangUpContactJob.perform_later(call.id)
  end

  def recheck_failed_add(wait)
    Voice::FailedAddRecheckJob.set(wait: wait.seconds).perform_later(call.id, participant_label, participant_call_sid)
  end

  # Returns :release, :end, a retry delay, or nil when no action is needed.
  def failed_add_outcome(user_id)
    call.record_agent_leg!(participant_call_sid, 'gone')
    return if call.agent_leg_joined?(except: participant_call_sid)

    wait = call.agent_leg_join_wait(except: participant_call_sid)
    return wait if wait
    return release_failed_claim(user_id) if call.ringing? && call.incoming?
    return unless call.ringing? || call.in_progress?

    status_manager.process_status_update(failed_add_status, timestamp: now)
    :end
  end

  # The contact's answer callback can arrive after the failed join.
  def failed_add_status
    return 'no_answer'.tap { call.merge_meta!('unanswered_by_failed_join' => true) } if call.ringing?

    call.accepted_broadcast_at.present? ? 'completed' : 'failed'
  end

  # Lock order: call, then conversation.
  def release_claim_assignment(user_id)
    return unless user_id && call.reload.ring_state['assigned_by_claim'] == user_id

    conversation = call.conversation
    call.with_lock do
      next unless call.ring_state['assigned_by_claim'] == user_id

      conversation.with_lock do
        claimant = call.accepted_by_agent_id
        next if claimant == user_id

        # Consuming the marker prevents duplicate callbacks from undoing later assignments.
        Call.where(id: call.id).update_all("ring_state = ring_state - 'assigned_by_claim'") # rubocop:disable Rails/SkipsModelValidations
        next unless conversation.assignee_id == user_id

        Conversations::AssignmentService.new(conversation: conversation, assignee_id: claimant).perform
        conference_service.remember_claim_assignment(claimant) if claimant
      end
    end
  end

  def release_failed_claim(user_id)
    conference_service.release_claim!(user_id)
    :release
  end

  def claimant_leaving_unjoined_call?
    call.ringing? && agent_participant? && call.accepted_by_agent_id.present? &&
      call.accepted_by_agent_id == extract_user_id
  end

  def other_agents_remain?
    conference_service.agents_remain?(leaving_call_sid: participant_call_sid)
  rescue StandardError => e
    Rails.logger.error("[VOICE] call #{call.id}: could not list conference participants: #{e.class}: #{e.message}")
    Voice::EndConferenceJob.perform_later(call.id, leaving_call_sid: participant_call_sid)
    true
  end

  def end_conference!
    conference_service.end_conference
  rescue StandardError => e
    Rails.logger.error("[VOICE] call #{call.id}: could not end conference after a leave: #{e.class}: #{e.message}")
    Voice::EndConferenceJob.perform_later(call.id)
  end

  def conference_service = (@conference_service ||= Voice::Provider::Twilio::ConferenceService.new(call: call))

  def finalize!
    return if Call::TERMINAL_STATUSES.include?(call.status)

    status_manager.process_status_update('completed', timestamp: now)
  end

  def agent_participant? = participant_label.to_s.start_with?('agent-')

  def now = Time.zone.now.to_i
end
