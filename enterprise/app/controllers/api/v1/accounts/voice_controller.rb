class Api::V1::Accounts::VoiceController < Api::V1::Accounts::BaseController
  before_action :set_voice_inbox_for_conference

  def conference_token
    render json: Voice::TokenService.new(
      inbox: @voice_inbox,
      user: Current.user,
      account: Current.account
    ).generate
  end

  def conference_join
    conversation = fetch_conversation_by_display_id
    ensure_call_sid!(conversation)

    conference_service = Voice::Provider::Twilio::ConferenceService.new(conversation: conversation)
    conference_sid = conference_service.ensure_conference_sid
    conference_service.mark_agent_joined(user: current_user)

    render json: {
      status: 'success',
      id: conversation.display_id,
      conference_sid: conference_sid,
      using_webrtc: true
    }
  end

  def conference_leave
    conversation = fetch_conversation_by_display_id
    Voice::Provider::Twilio::ConferenceService.new(conversation: conversation).end_conference
    render json: { status: 'success', id: conversation.display_id }
  end

  private

  def ensure_call_sid!(conversation)
    return conversation.identifier if conversation.identifier.present?

    incoming_sid = params.require(:call_sid)

    conversation.update!(identifier: incoming_sid)
    incoming_sid
  end

  def set_voice_inbox_for_conference
    @voice_inbox = Current.account.inboxes.find(params[:id] || params[:inbox_id])
    authorize @voice_inbox
  end

  def fetch_conversation_by_display_id
    cid = params[:conversation_id]
    raise ActiveRecord::RecordNotFound, 'conversation_id required' if cid.blank?

    Current.account.conversations.find_by!(display_id: cid)
  end
end
