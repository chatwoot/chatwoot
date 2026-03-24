class Whatsapp::CallService
  pattr_initialize [:wa_call!, :agent!]

  def pre_accept_and_accept(sdp_answer)
    wa_call.with_lock do
      ensure_ringing!
      ensure_not_already_taken!

      provider = wa_call.inbox.channel.provider_service
      call_id = wa_call.call_id
      fixed_sdp = fix_sdp_setup(sdp_answer)

      # Step 1: pre_accept (with SDP answer — required by Meta)
      pre_response = provider.pre_accept_call(call_id, fixed_sdp)
      raise Whatsapp::CallErrors::NotRinging, 'Meta pre_accept failed' unless pre_response

      # Step 2: accept with same SDP answer
      accept_response = provider.accept_call(call_id, fixed_sdp)
      raise Whatsapp::CallErrors::NotRinging, 'Meta accept failed' unless accept_response

      wa_call.update!(
        status: 'accepted',
        accepted_by_agent_id: agent.id
      )
    end

    Whatsapp::CallMessageBuilder.update_status!(wa_call: wa_call, status: 'accepted', agent: agent)
    update_conversation_call_status('in-progress')
    broadcast_accepted
    wa_call
  end

  def reject
    wa_call.reload
    return wa_call if wa_call.terminal? || wa_call.accepted?

    provider = wa_call.inbox.channel.provider_service
    success = provider.reject_call(wa_call.call_id)
    Rails.logger.error "[WHATSAPP CALL] reject_call API returned false for call #{wa_call.call_id}" unless success

    wa_call.update!(status: 'rejected')
    Whatsapp::CallMessageBuilder.update_status!(wa_call: wa_call, status: 'rejected')
    update_conversation_call_status('failed')
    broadcast_call_ended
    wa_call
  end

  def terminate
    return wa_call if wa_call.terminal?

    provider = wa_call.inbox.channel.provider_service
    success = provider.terminate_call(wa_call.call_id)
    Rails.logger.error "[WHATSAPP CALL] terminate_call API returned false for call #{wa_call.call_id}" unless success

    wa_call.update!(status: 'ended')
    Whatsapp::CallMessageBuilder.update_status!(wa_call: wa_call, status: 'ended')
    update_conversation_call_status('completed')
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

  def update_conversation_call_status(mapped_status)
    conversation = wa_call.conversation
    attrs = (conversation.additional_attributes || {}).merge('call_status' => mapped_status)
    conversation.update!(additional_attributes: attrs)
  end

  def broadcast_accepted
    payload = {
      event: 'whatsapp_call.accepted',
      data: {
        account_id: wa_call.account_id,
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
        account_id: wa_call.account_id,
        id: wa_call.id,
        call_id: wa_call.call_id,
        status: wa_call.status,
        conversation_id: wa_call.conversation_id
      }
    }
    ActionCable.server.broadcast("account_#{wa_call.account_id}", payload)
  end
end
