class Whatsapp::CallService
  pattr_initialize [:call!, :agent!, :sdp_answer]

  def accept
    raise Voice::CallErrors::CallFailed, 'sdp_answer is required' if sdp_answer.blank?

    # All side effects under the lock so a concurrent terminate cannot finalize
    # the call between status update and the message/conversation/broadcast writes.
    call.with_lock do
      transition_to_in_progress!
      update_message_status('in_progress')
      update_conversation_call_status(call.display_status)
      broadcast(:accepted, accepted_by_agent_id: agent.id)
    end
    call
  end

  def reject
    call.with_lock do
      next if call.terminal? || call.in_progress?

      invoke_provider!(:reject_call)
      finalize_call('failed')
    end
    call
  end

  def terminate
    call.with_lock do
      next if call.terminal?

      invoke_provider!(:terminate_call)
      # Compute duration from started_at locally — the webhook arrives after the
      # call is already terminal and the idempotency guard there bails before it
      # can fill these fields, so we have to record them here.
      if call.in_progress?
        duration = call.started_at ? (Time.current - call.started_at).to_i : nil
        finalize_call('completed', duration_seconds: duration, end_reason: 'agent_hangup')
      else
        # Agent hangs up before contact picks up → no_answer; mirrors the webhook terminate path.
        finalize_call('no_answer', end_reason: 'agent_hangup')
      end
    end
    call
  end

  private

  def transition_to_in_progress!
    # Order matters: in_progress and terminal both make ringing? false, so we have to
    # branch on in_progress? first to surface the distinct AlreadyAccepted state.
    raise Voice::CallErrors::AlreadyAccepted, 'Call already accepted by another agent' if call.in_progress?
    raise Voice::CallErrors::NotRinging, 'Call is not in ringing state' unless call.ringing?

    forward_answer_to_meta!
    call.update!(status: 'in_progress', accepted_by_agent_id: agent.id, started_at: Time.current,
                 meta: (call.meta || {}).merge('sdp_answer' => sdp_answer))
    claim_conversation_for_agent
  end

  def forward_answer_to_meta!
    invoke_provider!(:pre_accept_call, sdp_answer)
    invoke_provider!(:accept_call, sdp_answer)
  end

  # Take ownership of the conversation if no one holds it; leave assignee alone otherwise (transfer via UI).
  def claim_conversation_for_agent
    call.conversation.update!(assignee: agent) if call.conversation.assignee_id.blank?
  end

  # Raise on Meta failure (bool false or transport error) so callers bail before
  # finalizing local state — otherwise we'd mark a still-active call as ended
  # and broadcast voice_call.ended while Meta thinks it's live.
  def invoke_provider!(method, *)
    success = call.inbox.channel.provider_service.public_send(method, call.provider_call_id, *)
    raise Voice::CallErrors::CallFailed, "Meta #{method} failed" unless success
  rescue Voice::CallErrors::CallFailed
    raise
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP CALL] #{method} failed: #{e.class} #{e.message}"
    raise Voice::CallErrors::CallFailed, "Meta #{method} failed"
  end

  def finalize_call(status, **attrs)
    meta = (call.meta || {}).merge('ended_at' => Time.zone.now.to_i)
    call.update!(status: status, meta: meta, **attrs)
    update_message_status(status, duration_seconds: attrs[:duration_seconds])
    update_conversation_call_status(call.display_status)
    broadcast(:ended, status: call.display_status)
  end

  def update_message_status(status, duration_seconds: nil)
    Voice::CallMessageBuilder.new(call).update_status!(status: status, agent: agent, duration_seconds: duration_seconds)
  end

  def update_conversation_call_status(status)
    call.conversation.update!(
      additional_attributes: (call.conversation.additional_attributes || {}).merge('call_status' => status)
    )
  end

  def broadcast(event, **extra)
    payload = {
      event: "voice_call.#{event}",
      data: { id: call.id, call_id: call.provider_call_id, provider: call.provider,
              conversation_id: call.conversation_id, account_id: call.account_id }.merge(extra)
    }
    ActionCable.server.broadcast("account_#{call.account_id}", payload)
  end
end
