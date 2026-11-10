module Voice::Conference::FailedAddHandling
  private

  def failed_add?
    agent_participant? && leave_reason == 'participant_add_failed'
  end

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
    if call.ringing?
      call.merge_meta!('unanswered_by_failed_join' => true)
      return 'no_answer'
    end

    call.accepted_broadcast_at.present? ? 'completed' : 'failed'
  end

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
end
