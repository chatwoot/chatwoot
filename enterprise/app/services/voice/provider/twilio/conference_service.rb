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

  def end_conference
    return if call.conference_sid.blank?

    client = call.inbox.channel.client
    client
      .conferences
      .list(friendly_name: call.conference_sid, status: 'in-progress')
      .each { |conf| client.conferences(conf.sid).update(status: 'completed') }
  end

  private

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
    return if conversation.assignee_id.present?

    Conversations::AssignmentService.new(conversation: conversation, assignee_id: user.id).perform
  end
end
