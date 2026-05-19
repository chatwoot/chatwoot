module Enterprise::Webhooks::WhatsappEventsJob
  def handle_message_events(channel, params)
    return handle_call_events(channel, params) if call_event?(params)
    return handle_call_permission_reply(channel, params) if call_permission_reply?(params)

    super
  end

  private

  # Lock per-call_id inside handle_call_events instead of the parent's per-sender mutex.
  def contact_sender_id(params)
    return nil if call_event?(params)

    super
  end

  def call_event?(params)
    params.dig(:entry, 0, :changes, 0, :field) == 'calls'
  end

  def call_permission_reply?(params)
    params.dig(:entry, 0, :changes, 0, :value, :messages, 0, :interactive, :type) == 'call_permission_reply'
  end

  # Per-call_id mutex so connect/status/terminate for the same call serialize
  # across batches. Meta delivers two payload shapes under field=calls:
  #   - value.calls[]    → event-based (connect, terminate)
  #   - value.statuses[] → status-based (RINGING, ACCEPTED) — the real pickup
  #     signal for outbound; without this, only `connect` (tunnel-up) is seen
  #     and timer/recorder kick off before the contact actually answers.
  def handle_call_events(channel, params)
    value = params.dig(:entry, 0, :changes, 0, :value) || {}

    Array(value[:calls]).each do |call_payload|
      with_call_lock(channel, call_payload[:id]) do
        Whatsapp::IncomingCallService.new(inbox: channel.inbox, params: { calls: [call_payload] }).perform
      end
    end

    Array(value[:statuses]).each do |status_payload|
      next unless status_payload[:type] == 'call'

      with_call_lock(channel, status_payload[:id]) do
        Whatsapp::IncomingCallService.new(inbox: channel.inbox, params: { statuses: [status_payload] }).perform
      end
    end
  end

  def with_call_lock(channel, call_id, &)
    lock_key = format(::Redis::Alfred::WHATSAPP_MESSAGE_MUTEX,
                      inbox_id: channel.inbox.id, sender_id: "call:#{call_id}")
    with_lock(lock_key, 30.seconds, &)
  end

  def handle_call_permission_reply(channel, params)
    Whatsapp::CallPermissionReplyService.new(inbox: channel.inbox, params: params).perform
  end
end
