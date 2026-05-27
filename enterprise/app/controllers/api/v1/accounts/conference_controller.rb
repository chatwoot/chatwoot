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

    render json: {
      status: 'success',
      id: call.conversation.display_id,
      conference_sid: conference_sid,
      using_webrtc: true
    }
  end

  def destroy
    call = resolve_call!
    rejecting = agent_rejecting_before_pickup?(call)
    # Tear down provider side first so a teardown failure leaves the call repairable.
    Voice::Provider::Twilio::ConferenceService.new(call: call).end_conference
    finalize_as_agent_reject!(call) if rejecting
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

  # A hangup before pickup is treated as an agent rejection, matching WhatsApp.
  def agent_rejecting_before_pickup?(call)
    call.ringing? && call.accepted_by_agent_id.nil?
  end

  def finalize_as_agent_reject!(call)
    # Re-check under a row lock: a webhook may have accepted/completed the call
    # while end_conference was in flight, so don't force agent_rejected on stale state.
    rejected = call.with_lock do
      next false unless agent_rejecting_before_pickup?(call)

      call.update!(status: 'failed', end_reason: 'agent_rejected', accepted_by_agent_id: Current.user.id)
      true
    end
    Voice::CallMessageBuilder.new(call).update_status!(status: 'failed', agent: Current.user) if rejected
  end
end
