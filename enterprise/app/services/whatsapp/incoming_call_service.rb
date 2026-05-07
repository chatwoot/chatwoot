class Whatsapp::IncomingCallService
  pattr_initialize [:inbox!, :params!]

  def perform
    return unless inbox.channel.voice_enabled?

    Array(params[:calls]).each { |c| handle_event(c.with_indifferent_access) }
    Array(params[:statuses]).each { |s| handle_status(s.with_indifferent_access) }
  end

  private

  def handle_event(payload)
    case payload[:event]
    when 'connect' then handle_connect(payload)
    when 'terminate' then handle_terminate(payload)
    else Rails.logger.warn "[WHATSAPP CALL] Unknown call event: #{payload[:event]}"
    end
  end

  # Meta's `connect` event for outbound calls fires when the WebRTC tunnel is
  # up — empirically ~20s before the contact actually answers. The real pickup
  # is reported as a separate webhook with status=ACCEPTED, and is what
  # `terminate.start_time` aligns to. Treat ACCEPTED as the pickup transition.
  def handle_status(payload)
    return unless payload[:type] == 'call'

    call = Call.whatsapp.find_by(provider_call_id: payload[:id])
    return unless call

    case payload[:status]
    when 'ACCEPTED' then mark_outbound_accepted(call, payload)
    when 'RINGING' then nil # informational
    else Rails.logger.info "[WHATSAPP CALL] Unhandled call status: #{payload[:status]} for #{payload[:id]}"
    end
  end

  # with_lock + reload here serializes against Whatsapp::CallService (agent
  # actions hold call.with_lock across the Meta API call), so a webhook racing
  # with a terminate can't overwrite a freshly-finalized terminal status.
  def mark_outbound_accepted(call, payload)
    call.with_lock do
      next unless call.outgoing?
      next if call.in_progress? || call.terminal?

      started_at = Time.zone.at(payload[:timestamp].to_i) if payload[:timestamp].present?
      update_call!(call, 'in_progress', started_at: started_at || Time.current)
      broadcast(call, 'voice_call.outbound_accepted')
    end
  end

  def handle_connect(payload)
    call = Call.whatsapp.find_by(provider_call_id: payload[:id])
    if call.nil?
      # Only an `offer` payload is a real inbound caller. An `answer` with no
      # local row means Meta beat our outbound `Call.create!` (tiny window
      # between initiate API response and DB insert) — do not mint an inbound
      # row for it; the next status webhook (or a retry) will find it.
      return create_inbound_call(payload) if inbound_offer?(payload)

      Rails.logger.warn "[WHATSAPP CALL] Outbound connect for unknown call #{payload[:id]}; skipping"
      return
    end

    return accept_outbound_call(call, payload) if call.outgoing?

    Rails.logger.info "[WHATSAPP CALL] Duplicate inbound connect for #{payload[:id]}; ignoring"
  end

  def inbound_offer?(payload)
    payload.dig(:session, :sdp_type).to_s.downcase == 'offer'
  end

  def create_inbound_call(payload)
    sdp_offer = payload.dig(:session, :sdp)
    call = Voice::InboundCallBuilder.perform!(
      inbox: inbox, from_number: "+#{payload[:from]}", call_sid: payload[:id],
      provider: :whatsapp,
      extra_meta: { 'sdp_offer' => sdp_offer, 'ice_servers' => Call.default_ice_servers }
    )
    update_conversation(call)
    broadcast_incoming(call, sdp_offer)
  end

  # `connect` is the WebRTC tunnel-ready signal, not the pickup signal. Apply
  # Meta's SDP answer so the handshake completes during ringing; the call
  # stays in `ringing` until status=ACCEPTED arrives.
  def accept_outbound_call(call, payload)
    call.with_lock do
      next if call.in_progress? || call.terminal?

      # Pin setup:active so browsers don't renegotiate when Meta echoes actpass.
      sdp_answer = payload.dig(:session, :sdp)&.gsub('a=setup:actpass', 'a=setup:active')
      call.update!(meta: (call.meta || {}).merge('sdp_answer' => sdp_answer))
      broadcast(call, 'voice_call.outbound_connected', sdp_answer: sdp_answer)
    end
  end

  def handle_terminate(payload)
    call = Call.whatsapp.find_by(provider_call_id: payload[:id])
    if call.nil?
      # No row yet means either an out-of-order terminate (rare in practice — Meta
      # delivery is FIFO) or, more dangerously, an outbound terminate landing in
      # the window between the controller's Meta API call and Call.create!.
      # Materialising as inbound here would collide with the unique
      # (provider, provider_call_id) index. Skip; controller commits seal it.
      Rails.logger.warn "[WHATSAPP CALL] Terminate for unknown call #{payload[:id]}; skipping"
      return
    end

    call.with_lock do
      # Webhook retries can re-deliver terminate after we've already finalized the
      # call; don't recompute status or a duration=0 retry can flip a completed
      # short call back to no_answer.
      next if call.terminal?

      duration = payload[:duration]&.to_i
      status = answered?(call, duration) ? 'completed' : 'no_answer'
      meta = (call.meta || {}).merge('ended_at' => Time.zone.now.to_i)
      update_call!(call, status, duration_seconds: duration, end_reason: payload[:terminate_reason], meta: meta)
      broadcast(call, 'voice_call.ended', status: call.display_status, duration_seconds: call.duration_seconds)
    end
  end

  # accepted_by_agent_id is the initiating agent on outbound calls, so it only signals "answered" for inbound.
  def answered?(call, duration)
    call.in_progress? || duration.to_i.positive? || (call.incoming? && call.accepted_by_agent_id.present?)
  end

  def update_call!(call, status, **attrs)
    call.update!(status: status, **attrs)
    Voice::CallMessageBuilder.new(call).update_status!(status: status, agent: call.accepted_by_agent,
                                                       duration_seconds: attrs[:duration_seconds])
    update_conversation(call)
  end

  def update_conversation(call)
    call.conversation.update!(
      additional_attributes: (call.conversation.additional_attributes || {}).merge(
        'call_status' => call.display_status, 'call_direction' => call.direction_label
      )
    )
  end

  # Ring the assignee if assigned; otherwise account-wide so any agent can pick up.
  def broadcast_incoming(call, sdp_offer)
    contact = call.contact
    token = call.conversation.assignee&.pubsub_token
    broadcast(call, 'voice_call.incoming',
              streams: token ? [token] : account_streams,
              direction: call.direction_label, inbox_id: call.inbox_id,
              sdp_offer: sdp_offer, ice_servers: Call.default_ice_servers,
              caller: { name: contact.name, phone: contact.phone_number, avatar: contact.avatar_url })
  end

  def broadcast(call, event, streams: account_streams, **extra)
    payload = { event: event, data: base_payload(call).merge(extra) }
    streams.each { |s| ActionCable.server.broadcast(s, payload) }
  end

  def account_streams
    ["account_#{inbox.account_id}"]
  end

  def base_payload(call)
    { account_id: inbox.account_id, id: call.id, call_id: call.provider_call_id,
      provider: 'whatsapp', conversation_id: call.conversation_id }
  end
end
