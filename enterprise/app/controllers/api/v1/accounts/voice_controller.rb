require 'twilio-ruby'

class Api::V1::Accounts::VoiceController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation, only: %i[end_call join_call reject_call]
  before_action :set_voice_inbox, only: %i[token]

  # ---------- PUBLIC ACTIONS --------------------------------------------------

  def end_call
    call_sid = params[:call_sid] || convo_attr('call_sid')
    return render_not_found('active call') unless call_sid

    manager = Voice::CallStatus::Manager.new(conversation: @conversation,
                                             call_sid:    call_sid,
                                             provider:    :twilio)
    # If the call never connected (still ringing) treat as no_answer for better UX on outbound calls
    desired = if @conversation.additional_attributes&.dig('call_status') == 'ringing'
                'no_answer'
              else
                'completed'
              end
    manager.process_status_update(desired, nil, false, "Call ended by #{current_user.name}")

    # Attempt to end the Twilio call leg; ignore failures so our UI state finalizes
    begin
      twilio_client.calls(call_sid).update(status: 'completed') if in_progress?(call_sid)
    rescue StandardError
      # ignore
    end

    # Force-broadcast a conversation update so the UI reflects terminal status
    begin
      @conversation.reload
      @conversation.dispatch_conversation_updated_event
    rescue StandardError
      # ignore broadcast failures
    end

    render_success('Call successfully ended')
  rescue StandardError => e
    render_error("Failed to end call: #{e.message}")
  end

  def join_call
    call_sid = params[:call_sid] || convo_attr('call_sid')
    outbound  = convo_attr('requires_agent_join') == true

    return render_not_found('active call') unless call_sid || outbound

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
    render_error("Failed to join call: #{e.message}")
  end

  def reject_call
    call_sid = params[:call_sid] || convo_attr('call_sid')
    return render_not_found('active call') unless call_sid

    # Attempt to hang up the caller if still ringing/in-progress
    begin
      twilio_client.calls(call_sid).update(status: 'completed') if in_progress?(call_sid)
    rescue StandardError
      # ignore Twilio failures; still proceed to update local state
    end

    # Mark rejection metadata and set call status to no_answer via manager for consistency
    @conversation.update!(additional_attributes: convo_attrs.merge(
      'agent_rejected' => true,
      'rejected_at'    => Time.current.to_i,
      'rejected_by'    => user_meta
    ))

    Voice::CallStatus::Manager.new(conversation: @conversation,
                                   call_sid:    call_sid,
                                   provider:    :twilio)
                              .process_status_update('no_answer', nil, false, "#{current_user.name} declined the call")

    render_success('Call rejected by agent')
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

  # ---------- PRIVATE ---------------------------------------------------------

  private

  # ---- Helpers ---------------------------------------------------------------

  def render_success(msg) = render json: { status: 'success', message: msg }
  def render_not_found(resource) = render json: { error: "No #{resource} found" }, status: :not_found
  def render_error(msg) = render json: { error: msg }, status: :internal_server_error

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

    # Do not flip status back from a terminal state
    terminal = %w[ended missed no_answer]
    unless terminal.include?(convo_attr('call_status')) || convo_attr('call_ended_at').present?
      attrs['call_status'] = 'in_progress'
      @conversation.update!(additional_attributes: attrs)

      Voice::CallStatus::Manager.new(conversation: @conversation,
                                     call_sid:    call_sid,
                                     provider:    :twilio)
                                .process_status_update('in_progress', nil, false, "#{current_user.name} joined the call")
    else
      @conversation.update!(additional_attributes: attrs)
    end
  end


  # ---- Tokens ---------------------------------------------------------------

  def set_voice_inbox
    @voice_inbox = Current.account.inboxes.find(params[:inbox_id])
  end
end
