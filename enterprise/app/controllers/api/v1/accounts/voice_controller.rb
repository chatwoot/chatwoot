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
  rescue StandardError => e
    Rails.logger.error("VOICE_CONFERENCE_TOKEN_ERROR #{e.class}: #{e.message}")
    Sentry.capture_exception(e) if defined?(Sentry)
    Raven.capture_exception(e) if defined?(Raven)
    render json: { error: 'failed_to_generate_token', code: 'token_error', details: e.message }, status: :internal_server_error
  end

  # POST /api/v1/accounts/:account_id/inboxes/:inbox_id/conference
  def conference_join
    conversation = fetch_conversation_by_display_id
    # Deterministic conference SID from account + call_sid
    call_sid = conversation.identifier
    if call_sid.blank?
      incoming_sid = params[:call_sid].to_s
      if incoming_sid.blank?
        return render json: { error: 'conference_not_ready', code: 'not_ready', details: 'call_sid missing' }, status: :conflict
      end
      call_sid = incoming_sid
      conversation.update!(identifier: call_sid)
    end
    conference_sid = conversation.additional_attributes&.dig('conference_sid')
    if conference_sid.blank?
      conference_sid = "conf_account_#{Current.account.id}_conv_#{conversation.display_id}"
      conversation.update!(
        additional_attributes:
          (conversation.additional_attributes || {}).merge('conference_sid' => conference_sid)
      )
    end

    @conversation = conversation
    update_join_metadata!(conversation.identifier)
    render json: {
      status: 'success',
      conversation_id: conversation.display_id,
      conference_sid: conference_sid,
      using_webrtc: true,
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: 'conversation_not_found', code: 'not_found', details: e.message }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("VOICE_CONFERENCE_JOIN_ERROR #{e.class}: #{e.message}")
    Sentry.capture_exception(e) if defined?(Sentry)
    Raven.capture_exception(e) if defined?(Raven)
    render json: { error: 'failed_to_join_conference', code: 'join_error', details: e.message }, status: :internal_server_error
  end

  # DELETE /api/v1/accounts/:account_id/inboxes/:inbox_id/conference?conversation_id=:id
  def conference_leave
    conversation = fetch_conversation_by_display_id
    # End the conference when an agent leaves from the app
    Voice::ConferenceEndService.new(conversation: conversation).perform
    render json: { status: 'success', conversation_id: conversation.display_id }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: 'conversation_not_found', code: 'not_found', details: e.message }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("VOICE_CONFERENCE_LEAVE_ERROR #{e.class}: #{e.message}")
    Sentry.capture_exception(e) if defined?(Sentry)
    Raven.capture_exception(e) if defined?(Raven)
    render json: { error: 'failed_to_leave_conference', code: 'leave_error', details: e.message }, status: :internal_server_error
  end

  private

  def convo_attrs
    @conversation.additional_attributes || {}
  end

  def convo_attr(key)
    convo_attrs[key]
  end

  def user_meta
    { id: current_user.id, name: current_user.name }
  end

  def update_join_metadata!(call_sid)
    attrs = convo_attrs.merge(
      'agent_joined' => true,
      'joined_at'    => Time.current.to_i,
      'joined_by'    => user_meta
    )

    @conversation.update!(additional_attributes: attrs)
  end

  def set_voice_inbox_for_conference
    @voice_inbox = Current.account.inboxes.find(params[:id] || params[:inbox_id])
    authorize @voice_inbox
  end

  def fetch_conversation_by_display_id
    cid = params[:conversation_id] || params[:conversationId]
    raise ActiveRecord::RecordNotFound, 'conversation_id required' if cid.blank?
    Current.account.conversations.find_by!(display_id: cid)
  end
end
