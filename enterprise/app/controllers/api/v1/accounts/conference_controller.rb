class Api::V1::Accounts::ConferenceController < Api::V1::Accounts::BaseController
  before_action :set_voice_inbox_for_conference
  rescue_from CustomExceptions::CallAlreadyAccepted, with: :render_call_already_accepted
  rescue_from CustomExceptions::CallTerminationInProgress, with: :render_call_termination_in_progress

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
    termination = claim_termination!(call)
    provider_teardown_succeeded = false

    begin
      conference_service.end_provider_call
      provider_teardown_succeeded = true
      finalize_call!(call, termination)
      conference_service.complete_conference
    ensure
      release_termination!(call, termination[:token], replay_pending: !provider_teardown_succeeded)
    end

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

  def render_call_termination_in_progress(error)
    render json: {
      error: error.message,
      code: 'call_termination_in_progress'
    }, status: :locked
  end

  def claim_termination!(call)
    termination = nil
    call.with_lock do
      next if call.terminal?

      Voice::CallTerminationGuard.clear_stale!(call)
      raise CustomExceptions::CallTerminationInProgress.new({}) if Voice::CallTerminationGuard.active?(call)

      termination = { token: SecureRandom.uuid, intent: termination_intent_for(call) }
      call.update!(meta: Voice::CallTerminationGuard.claim_meta(call, token: termination[:token]))
    end
    termination || { token: nil, intent: nil }
  end

  def termination_intent_for(call)
    if call.ringing? && call.accepted_by_agent_id.nil?
      { status: 'rejected', end_reason: 'agent_rejected', accepted_by_agent_id: Current.user.id }
    elsif call.in_progress?
      { status: 'completed', end_reason: 'agent_hangup' }
    else
      { status: 'no_answer', end_reason: 'agent_hangup' }
    end
  end

  def release_termination!(call, token, replay_pending: false)
    return if token.blank?

    pending = nil
    call.with_lock do
      pending = Voice::CallTerminationGuard.pending_status(call) if replay_pending
      Voice::CallTerminationGuard.release!(call, token)
    end
    return if pending.blank?

    Voice::CallStatus::Manager.new(call: call).process_status_update(
      pending['status'],
      duration: pending['duration'],
      timestamp: pending['timestamp']
    )
  end

  def finalize_call!(call, termination)
    intent = termination[:intent]
    token = termination[:token]
    return if intent.blank? || token.blank?

    applied = false
    call.with_lock do
      next if call.terminal?
      next unless Voice::CallTerminationGuard.owned_by?(call, token)

      attrs = { end_reason: intent[:end_reason] }
      attrs[:accepted_by_agent_id] = intent[:accepted_by_agent_id] if intent[:accepted_by_agent_id]
      call.update!(attrs)
      Voice::CallStatus::Manager.new(call: call).process_status_update(
        intent[:status], allow_during_termination: true
      )
      applied = true
    end
    Voice::CallMessageBuilder.new(call).update_status!(status: intent[:status], agent: Current.user) if applied
  end
end
