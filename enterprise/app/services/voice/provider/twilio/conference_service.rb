class Voice::Provider::Twilio::ConferenceService
  pattr_initialize [:call!]

  PRE_ANSWER_PROVIDER_STATUSES = %w[queued initiated ringing].freeze
  TERMINAL_PROVIDER_STATUSES = %w[completed canceled failed busy no-answer].freeze

  def ensure_conference_sid
    call.with_lock do
      call.update!(conference_sid: call.default_conference_sid) if call.conference_sid.blank?
      call.conference_sid
    end
  end

  def mark_agent_joined(user:)
    claim_call!(user)
    assign_conversation!(user)
  end

  def end_conference
    end_provider_call
    complete_conference
  end

  def end_provider_call
    return if call.provider_call_id.blank?

    call_context = call.inbox.channel.client.calls(call.provider_call_id)
    provider_status = call_context.fetch.status.to_s
    terminate_provider_call(call_context, provider_status)
  end

  def complete_conference
    return if call.conference_sid.blank?

    client = call.inbox.channel.client
    client
      .conferences
      .list(friendly_name: call.conference_sid, status: 'in-progress')
      .each { |conf| client.conferences(conf.sid).update(status: 'completed') }
  end

  private

  def terminate_provider_call(call_context, provider_status, retry_state_race: true)
    return if TERMINAL_PROVIDER_STATUSES.include?(provider_status)

    target_status = provider_target_status(provider_status)
    call_context.update(status: target_status)
  rescue Twilio::REST::RestError => error
    refreshed_status = call_context.fetch.status.to_s
    return if TERMINAL_PROVIDER_STATUSES.include?(refreshed_status)

    refreshed_target = provider_target_status(refreshed_status)
    raise error unless retry_state_race && refreshed_target != target_status

    terminate_provider_call(call_context, refreshed_status, retry_state_race: false)
  end

  def provider_target_status(provider_status)
    PRE_ANSWER_PROVIDER_STATUSES.include?(provider_status) ? 'canceled' : 'completed'
  end

  def claim_call!(user)
    call.with_lock do
      Voice::CallTerminationGuard.clear_stale!(call)
      raise CustomExceptions::CallTerminationInProgress.new({}) if Voice::CallTerminationGuard.active?(call)

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
