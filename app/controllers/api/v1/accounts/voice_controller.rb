require 'twilio-ruby'

class Api::V1::Accounts::VoiceController < Api::V1::Accounts::BaseController
  before_action :fetch_conversation, only: %i[end_call join_call reject_call]
  skip_before_action :authenticate_user!, only: :twiml_for_client
  protect_from_forgery with: :null_session, only: :twiml_for_client

  before_action :render_options, if: -> { request.options? }
  after_action  :set_cors_headers, if: -> { action_name == 'twiml_for_client' }

  # ---------- PUBLIC ACTIONS --------------------------------------------------

  def end_call
    call_sid = params[:call_sid] || convo_attr('call_sid')
    return render_not_found('active call') unless call_sid

    twilio_client.calls(call_sid).update(status: 'completed') if in_progress?(call_sid)

    Voice::CallStatus::Manager.new(conversation: @conversation,
                                   call_sid:    call_sid,
                                   provider:    :twilio)
                              .process_status_update('completed', nil, false, "Call ended by #{current_user.name}")

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


  # TwiML for agent WebRTC dial‑in
  def twiml_for_client
    to          = params[:To] || params[:to]
    return render_twiml_error('Missing conference ID parameter') if to.blank?

    render xml: build_twiml(to), content_type: 'text/xml'
  rescue StandardError => e
    render_twiml_error(e.message)
  end

  # ---------- PRIVATE ---------------------------------------------------------

  private

  # ---- Helpers ---------------------------------------------------------------

  def render_options
    head :ok
  end

  def set_cors_headers
    headers['Content-Type']                 ||= 'text/xml; charset=utf-8'
    headers['Access-Control-Allow-Origin']   = '*'
    headers['Access-Control-Allow-Methods']  = 'POST, GET, OPTIONS'
    headers['Access-Control-Allow-Headers']  = 'Content-Type, X-Twilio-Signature'
    headers['Access-Control-Max-Age']        = '86400'
  end

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
    @conversation.update!(additional_attributes: convo_attrs.merge(
      'agent_joined' => true,
      'joined_at'    => Time.current.to_i,
      'joined_by'    => user_meta,
      'call_status'  => 'in_progress'
    ))

    Voice::CallStatus::Manager.new(conversation: @conversation,
                                   call_sid:    call_sid,
                                   provider:    :twilio)
                              .process_status_update('in_progress', nil, false, "#{current_user.name} joined the call")
  end


  # ---- TwiML -----------------------------------------------------------------

  def build_twiml(conference_sid)
    # Check if this is an outbound call by looking at the conversation
    is_outbound = @conversation&.additional_attributes&.dig('call_direction') == 'outbound'
    
    Twilio::TwiML::VoiceResponse.new do |r|

      r.dial do |dial|
        dial.conference(
          conference_sid,
          startConferenceOnEnter: !is_outbound,  # Don't start conference for outbound calls (contact already started it)
          endConferenceOnExit:    true,
          muted:                  false,
          beep:                   false,
          waitUrl:                '',
          earlyMedia:             true,
          statusCallback:         conference_callback_url,
          statusCallbackEvent:    'start end join leave',
          statusCallbackMethod:   'POST',
          participantLabel:       "agent-#{params[:agent_id] || current_user&.id}"
        )
      end
    end.to_s
  end

  def conference_callback_url
    account_id = params[:account_id] || Current.account&.id
    "#{base_url.chomp('/')}/api/v1/accounts/#{account_id}/channels/voice/webhooks/conference_status"
  end

  def base_url
    ENV.fetch('FRONTEND_URL', '')
  end

  # ---- TwiML Error -----------------------------------------------------------

  def render_twiml_error(message)
    response = Twilio::TwiML::VoiceResponse.new do |r|
      r.say(message: "Error: #{message}")
      r.hangup
    end
    set_cors_headers
    render xml: response.to_s, content_type: 'text/xml'
  end
end
