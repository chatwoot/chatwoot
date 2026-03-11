class Api::V1::Accounts::ConferenceController < Api::V1::Accounts::BaseController
  before_action :set_voice_inbox_for_conference

  def token
    render json: Voice::Provider::Twilio::TokenService.new(
      inbox: @voice_inbox,
      user: Current.user,
      account: Current.account
    ).generate
  end

  def create
    conversation = fetch_conversation_by_display_id
    return if claim_conversation!(conversation) == false

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

  def destroy
    conversation = fetch_conversation_by_display_id
    Voice::Provider::Twilio::ConferenceService.new(conversation: conversation).end_conference
    render json: { status: 'success', id: conversation.display_id }
  end

  private

  def claim_conversation!(conversation)
    conversation.with_lock do
      if conversation.assignee_id == current_user.id
        ensure_call_sid!(conversation)
        true
      elsif conversation.assignee.present?
        render_conflict_for_assigned_agent!(conversation.assignee.name)
        false
      else
        ensure_call_sid!(conversation)
        conversation.update!(assignee: current_user)
        true
      end
    end
  end

  def ensure_call_sid!(conversation)
    return conversation.identifier if conversation.identifier.present?

    incoming_sid = params.require(:call_sid)

    conversation.update!(identifier: incoming_sid)
    incoming_sid
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

  def render_conflict_for_assigned_agent!(agent_name)
    render json: { error: "#{agent_name} is already handling the call." }, status: :conflict
  end
end
