class Voice::Provider::Twilio::ConferenceService
  pattr_initialize [:call!]

  def ensure_conference_sid
    return call.conference_sid if call.conference_sid.present?

    call.merge_meta!('conference_sid' => call.default_conference_sid)
    call.conference_sid
  end

  # `attempt` identifies the connection the agent is about to open, which passes the same id
  # to Twilio; a client that sends none holds no place for it
  def mark_agent_joined(user:, attempt: nil)
    claim_call!(user, attempt)
    assign_conversation!(user)
  end

  def end_conference
    return if call.conference_sid.blank?

    in_progress_conferences.each { |conf| client.conferences(conf.sid).update(status: 'completed') }
  end

  # Whether an agent leg other than the one leaving is still on the conference. Legs are
  # told apart by call SID: an agent who reconnected carries the same label as the leg
  # that left.
  def agents_remain?(leaving_call_sid:)
    return false if call.conference_sid.blank?

    in_progress_conferences.any? { |conf| other_agent_present?(conf.sid, leaving_call_sid) }
  end

  # Hangs up legs that never joined the conference (e.g. a PSTN leg still ringing). `completed` ends
  # queued, ringing and in-progress legs alike (`canceled` skips in-progress); Twilio 200s on an ended leg.
  def terminate_call
    client = call.inbox.channel.client
    [call.provider_call_id, call.parent_call_sid].compact_blank.uniq.each do |sid|
      client.calls(sid).update(status: 'completed')
    end
  end

  # The conversation was assigned by this claim, so a leg Twilio then fails to add can
  # give it back
  def remember_claim_assignment(user_id)
    Call.where(id: call.id).update_all(['ring_state = ring_state || ?::jsonb', { 'assigned_by_claim' => user_id }.to_json]) # rubocop:disable Rails/SkipsModelValidations
  end

  # Completes the call once no agent connection is still on its way in, under the row lock
  # that opening a connection takes, so a connection either counts here or finds the call
  # over and is hung up. A connection that joined since the participants were looked up
  # (`since`) is on the call. Returns 0 for a connection on the call, the seconds to wait
  # for the connections still joining, or nil once the call is completed.
  def complete_unless_agent_joining(leaving_call_sid:, since:)
    call.with_lock do
      next 0 if call.agent_leg_joined?(except: leaving_call_sid, since: since)

      wait = call.agent_leg_join_wait(except: leaving_call_sid)
      next wait if wait

      Voice::CallStatus::Manager.new(call: call).process_status_update('completed', timestamp: Time.zone.now.to_i) unless call.terminal?
      nil
    end
  end

  private

  def client
    @client ||= call.inbox.channel.client
  end

  def in_progress_conferences
    client.conferences.list(friendly_name: call.conference_sid, status: 'in-progress')
  end

  def other_agent_present?(conference_sid, leaving_call_sid)
    client.conferences(conference_sid).participants.list.any? do |participant|
      participant.label.to_s.start_with?('agent-') && participant.call_sid != leaving_call_sid
    end
  end

  # The agent's connection is on its way from here, before Twilio asks for its instructions
  def claim_call!(user, attempt)
    call.with_lock do
      raise_already_accepted!(call.accepted_by_agent) if claimed_by_other_agent?(user)
      call.update!(accepted_by_agent: user) if call.accepted_by_agent_id != user.id
      next if attempt.blank?

      # A newer attempt replaces older ones, which may never have reached Twilio
      call.retire_pending_agent_legs!
      call.record_agent_leg!(Call.pending_agent_leg(attempt), 'joining')
    end
  end

  def claimed_by_other_agent?(user)
    call.accepted_by_agent_id.present? && call.accepted_by_agent_id != user.id
  end

  def raise_already_accepted!(agent)
    raise CustomExceptions::CallAlreadyAccepted.new(agent_name: agent&.available_name || agent&.name)
  end

  # Existing assignments win — manual reassignment and pre-call assignment
  # (e.g., lock_to_single_conversation) shouldn't be stomped on pickup.
  def assign_conversation!(user)
    conversation = call.conversation
    return if conversation.assigned_entity.present?

    Conversations::AssignmentService.new(conversation: conversation, assignee_id: user.id).perform
    remember_claim_assignment(user.id)
  end
end
