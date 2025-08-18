require 'twilio-ruby'

class Api::V1::Accounts::VoiceController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation, only: %i[end_call join_call reject_call]
  before_action :set_voice_inbox, only: %i[token]

  def end_call
    call_sid = params[:call_sid] || convo_attr('call_sid')
    return render_not_found_error('No active call found') unless call_sid

    begin
      twilio_client.calls(call_sid).update(status: 'completed') if in_progress?(call_sid)
    rescue StandardError
      # ignore provider errors
    end

    render json: { status: 'success', message: 'Call successfully ended' }
  rescue StandardError => e
    render_internal_server_error("Failed to end call: #{e.message}")
  end

  def join_call
    call_sid = params[:call_sid] || convo_attr('call_sid')
    outbound  = convo_attr('requires_agent_join') == true

    return render_not_found_error('No active call found') unless call_sid || outbound

    conference_sid = convo_attr('conference_sid') || create_conference_sid!
    update_join_metadata!(call_sid)

    render json: {
      status:         'success',
      message:        'Agent joining call via WebRTC',
      conference_sid: conference_sid,
      using_webrtc:   true,
      conversation_id: @conversation.display_id,
      account_id:     Current.account.id
    }
  rescue StandardError => e
    render_internal_server_error("Failed to join call: #{e.message}")
  end

  def reject_call
    call_sid = params[:call_sid] || convo_attr('call_sid')
    return render_not_found_error('No active call found') unless call_sid

    begin
      twilio_client.calls(call_sid).update(status: 'completed') if in_progress?(call_sid)
    rescue StandardError
      # ignore provider errors
    end

    # Mark rejection metadata; status will be updated via Twilio webhooks
    @conversation.update!(additional_attributes: convo_attrs.merge(
      'agent_rejected' => true,
      'rejected_at'    => Time.current.to_i,
      'rejected_by'    => user_meta
    ))

    render json: { status: 'success', message: 'Call rejected by agent' }
  end


  # Token for client SDK
  def token
    payload = Voice::TokenService.new(
      inbox: @voice_inbox,
      user: Current.user,
      account: Current.account
    ).generate

    render json: payload
  rescue StandardError => e
    Rails.logger.error("Voice::Token error: #{e.class} - #{e.message}")
    render json: { error: 'Failed to generate token' }, status: :internal_server_error
  end

  private


  def fetch_conversation
    @conversation = Current.account.conversations.find_by(display_id: params[:conversation_id])
  end

  def twilio_client
    @twilio_client ||= begin
      cfg = @conversation.inbox.channel.provider_config_hash
      Twilio::REST::Client.new(cfg['account_sid'], cfg['auth_token'])
    end
  end

  def in_progress?(call_sid)
    %w[in-progress ringing].include?(twilio_client.calls(call_sid).fetch.status)
  end

  def convo_attrs
    @conversation.additional_attributes || {}
  end

  def convo_attr(key)
    convo_attrs[key]
  end

  def user_meta
    { id: current_user.id, name: current_user.name }
  end

  def create_conference_sid!
    sid = "conf_account_#{Current.account.id}_conv_#{@conversation.display_id}"
    @conversation.update!(additional_attributes: convo_attrs.merge('conference_sid' => sid))
    sid
  end

  def update_join_metadata!(call_sid)
    attrs = convo_attrs.merge(
      'agent_joined' => true,
      'joined_at'    => Time.current.to_i,
      'joined_by'    => user_meta
    )

    @conversation.update!(additional_attributes: attrs)
  end


  # ---- Tokens ---------------------------------------------------------------

  def set_voice_inbox
    @voice_inbox = Current.account.inboxes.find(params[:inbox_id])
  end
end
