class Api::V1::Accounts::ConferenceController < Api::V1::Accounts::BaseController
  before_action :set_voice_inbox_for_conference
  rescue_from CustomExceptions::CallAlreadyAccepted, with: :render_call_already_accepted

  def token
    render json: Voice::Provider::Twilio::TokenService.new(
      inbox: @voice_inbox,
      user: Current.user,
      account: Current.account
    ).generate
  end

  def create
    call = resolve_call!

    conference_service = Voice::Provider::Twilio::ConferenceService.new(call: call)
    conference_sid = conference_service.ensure_conference_sid
    conference_service.mark_agent_joined(user: current_user)
    # voice_call.accepted broadcasts from Voice::Conference::Manager#join_agent! once
    # Twilio confirms the leg joined, not here — joinClientCall can still fail after this.

    render json: {
      status: 'success',
      id: call.conversation.display_id,
      conference_sid: conference_sid,
      using_webrtc: true
    }
  end

  def destroy
    call = resolve_call!
    conference_service = Voice::Provider::Twilio::ConferenceService.new(call: call)

    mark_termination_pending!(call)
    begin
      conference_service.end_provider_call
      # Once the provider leg is confirmed ended (or already terminal), persist the
      # intended local result immediately. Conference cleanup is secondary and may fail
      # independently without leaving the Call permanently nonterminal.
      finalize_call!(call)
      conference_service.complete_conference
    ensure
      clear_termination_pending!(call)
    end

    # Account-wide, so every other tab/agent stops showing this call as ringing/active —
    # matches the equivalent WhatsApp broadcast (Whatsapp::CallService#broadcast).
    call.broadcast_voice_call_event(:ended, status: call.display_status)
    render json: { status: 'success', id: call.conversation.display_id }
  end

  private

  def resolve_call!
    sid = params[:call_sid].presence
    raise ActionController::ParameterMissing, :call_sid if sid.blank?

    conversation = fetch_conversation_by_display_id
    Call.where(inbox_id: @voice_inbox.id, provider: :twilio, conversation_id: conversation.id)
        .find_by!(provider_call_id: sid)
  end

  def set_voice_inbox_for_conference
    @voice_inbox = Current.account.inboxes.find(params[:inbox_id])
    authorize @voice_inbox, :show?
  end

  def fetch_conversation_by_display_id
    cid = params[:conversation_id]
    raise ActiveRecord::RecordNotFound, 'conversation_id required' if cid.blank?

    conversation = @voice_inbox.conversations.find_by!(display_id: cid)
    authorize conversation, :show?
    conversation
  end

  def render_call_already_accepted(error)
    render json: { error: error.message }, status: :conflict
  end

  # Keep the call repairable until Twilio confirms provider-leg teardown. The shared
  # Voice::CallStatus::Manager atomically suppresses provider-driven terminal
  # transitions while this flag is present. If provider teardown raises, ensure clears
  # the flag and the Call remains nonterminal so later callbacks can repair it.
  def mark_termination_pending!(call)
    call.with_lock do
      next if call.terminal?

      call.update!(meta: call.meta.merge('agent_termination_pending' => true))
    end
  end

  def clear_termination_pending!(call)
    call.with_lock do
      next unless call.meta['agent_termination_pending']

      call.update!(meta: call.meta.except('agent_termination_pending'))
    end
  end

  def finalize_call!(call)
    status = nil
    call.with_lock do
      next if call.terminal?

      if call.ringing? && call.accepted_by_agent_id.nil?
        status = 'rejected'
        call.update!(end_reason: 'agent_rejected', accepted_by_agent_id: Current.user.id)
      elsif call.in_progress?
        status = 'completed'
        call.update!(end_reason: 'agent_hangup')
      else
        status = 'no_answer'
        call.update!(end_reason: 'agent_hangup')
      end
      Voice::CallStatus::Manager.new(call: call).process_status_update(status, allow_during_termination: true)
    end
    Voice::CallMessageBuilder.new(call).update_status!(status: status, agent: Current.user) if status
  end
end
