class Api::V1::Accounts::VoiceController < Api::V1::Accounts::BaseController
  before_action :set_voice_inbox_for_conference, only: %i[conference_token conference_join conference_leave]

  # GET /api/v1/accounts/:account_id/inboxes/:inbox_id/conference_token
  def conference_token
    payload = Voice::TokenService.new(
      inbox: @voice_inbox,
      user: Current.user,
      account: Current.account
    ).generate
    render json: payload
  end

  # POST /api/v1/accounts/:account_id/inboxes/:inbox_id/conference
  def conference_join
    conversation = fetch_conversation
    ensure_identifier!(conversation)
    conference_sid = ensure_conference_sid!(conversation)
    mark_agent_joined!(conversation)

    render json: {
      status: 'success',
      conversation_id: conversation.display_id,
      conference_sid: conference_sid,
      using_webrtc: true
    }
  end

  # DELETE /api/v1/accounts/:account_id/inboxes/:inbox_id/conference?conversation_id=:id
  def conference_leave
    conversation = fetch_conversation
    Voice::Conference::EndService.new(conversation: conversation).perform
    render json: { status: 'success', conversation_id: conversation.display_id }
  end

  private

  def set_voice_inbox_for_conference
    @voice_inbox = Current.account.inboxes.find(params.require(:inbox_id))
    authorize @voice_inbox
  end

  def fetch_conversation
    conversation = @voice_inbox.conversations.find_by!(display_id: params.require(:conversation_id))

    authorize conversation, :show?

    conversation
  end

  def ensure_identifier!(conversation)
    return if conversation.identifier.present?

    call_sid = params.require(:call_sid)
    conversation.update!(identifier: call_sid)
  end

  def ensure_conference_sid!(conversation)
    attrs = conversation.additional_attributes || {}
    existing = attrs['conference_sid']
    return existing if existing.present?

    attrs['conference_sid'] = Voice::Conference::Name.for(conversation)
    conversation.update!(additional_attributes: attrs)
    attrs['conference_sid']
  end

  def mark_agent_joined!(conversation)
    attrs = conversation.additional_attributes || {}
    attrs['agent_joined'] = true
    attrs['joined_at'] = Time.current.to_i
    attrs['joined_by'] = { id: Current.user.id, name: Current.user.name }
    conversation.update!(additional_attributes: attrs)
  end
end
