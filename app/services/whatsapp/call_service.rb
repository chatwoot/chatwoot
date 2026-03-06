class Whatsapp::CallService
  pattr_initialize [:wa_call!, :agent!]

  def pre_accept_and_accept(sdp_answer)
    ensure_ringing!
    ensure_not_already_taken!

    provider = wa_call.inbox.channel.provider_service
    call_id = wa_call.call_id

    # Step 1: pre_accept
    pre_response = provider.pre_accept_call(call_id)
    raise "pre_accept failed: #{pre_response}" unless pre_response

    # Step 2: accept with SDP answer (fix setup attribute as required by Meta)
    fixed_sdp = fix_sdp_setup(sdp_answer)
    accept_response = provider.accept_call(call_id, fixed_sdp)
    raise "accept failed: #{accept_response}" unless accept_response

    wa_call.update!(
      status: 'accepted',
      accepted_by_agent_id: agent.id
    )

    broadcast_accepted
    wa_call
  end

  def reject
    return if wa_call.terminal?

    provider = wa_call.inbox.channel.provider_service
    provider.reject_call(wa_call.call_id)

    wa_call.update!(status: 'rejected')
    broadcast_call_ended
    wa_call
  end

  def terminate
    return if wa_call.terminal?

    provider = wa_call.inbox.channel.provider_service
    provider.terminate_call(wa_call.call_id)

    wa_call.update!(status: 'ended')
    broadcast_call_ended
    wa_call
  end

  private

  def ensure_ringing!
    raise Whatsapp::CallErrors::NotRinging, 'Call is not in ringing state' unless wa_call.ringing?
  end

  def ensure_not_already_taken!
    raise Whatsapp::CallErrors::AlreadyAccepted, 'Call already accepted by another agent' if wa_call.accepted?
  end

  def fix_sdp_setup(sdp)
    sdp.gsub('a=setup:actpass', 'a=setup:active')
  end

  def broadcast_accepted
    payload = {
      event: 'whatsapp_call.accepted',
      data: {
        id: wa_call.id,
        call_id: wa_call.call_id,
        accepted_by_agent_id: agent.id,
        conversation_id: wa_call.conversation_id
      }
    }
    ActionCable.server.broadcast("account_#{wa_call.account_id}", payload)
  end

  def broadcast_call_ended
    payload = {
      event: 'whatsapp_call.ended',
      data: {
        id: wa_call.id,
        call_id: wa_call.call_id,
        status: wa_call.status,
        conversation_id: wa_call.conversation_id
      }
    }
    ActionCable.server.broadcast("account_#{wa_call.account_id}", payload)
  end
end
