class Voice::Provider::Twilio::ConferenceService
  pattr_initialize [:call!]

  def ensure_conference_sid
    return call.conference_sid if call.conference_sid.present?

    call.update!(conference_sid: call.default_conference_sid)
    call.conference_sid
  end

  def mark_agent_joined(user:)
    claim_call!(user)
    assign_conversation!(user)
  end

  # The caller's own leg, ended directly: while no agent has joined, the conference has
  # not started and does not show up as in progress
  def hang_up_caller
    call.inbox.channel.client.calls(call.provider_call_id).update(status: 'completed')
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

  def claim_call!(user)
    call.with_lock do
      raise_already_accepted!(call.accepted_by_agent) if claimed_by_other_agent?(user)
      call.update!(accepted_by_agent: user) if call.accepted_by_agent_id != user.id
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
  end
end
