class Voice::StatusUpdateService
  pattr_initialize [:account!, :call_sid!, :call_status, { payload: {} }]

  TWILIO_STATUS_MAP = {
    'queued' => 'ringing',
    'initiated' => 'ringing',
    'ringing' => 'ringing',
    'in-progress' => 'in_progress',
    'inprogress' => 'in_progress',
    'answered' => 'in_progress',
    'completed' => 'completed',
    'busy' => 'no_answer',
    'no-answer' => 'no_answer',
    'failed' => 'failed',
    'canceled' => 'failed'
  }.freeze

  def perform
    normalized_status = normalize_status(call_status)
    return if normalized_status.blank?

    call = Call.where(account_id: account.id).find_by(provider: :twilio, provider_call_id: call_sid)
    return unless call

    record_provider_status(call)
    Voice::CallStatus::Manager.new(call: call).process_status_update(
      normalized_status,
      duration: payload_duration,
      timestamp: payload_timestamp
    )
  end

  private

  # Twilio's own status is kept beside the call's: queued, initiated and ringing all map
  # to ringing here, but only the last means the far handset is actually ringing, and a
  # client placing a call shows that moment. The message is rebroadcast so clients get
  # the change even when the call's status does not move.
  def record_provider_status(call)
    return if call.terminal?

    provider_status = call_status.to_s.downcase
    return if provider_status.blank? || call.provider_status == provider_status

    call.update!(provider_status: provider_status)
    call.message&.touch # rubocop:disable Rails/SkipsModelValidations
  end

  def normalize_status(status)
    return if status.to_s.strip.empty?

    TWILIO_STATUS_MAP[status.to_s.downcase]
  end

  def payload_duration
    return unless payload.is_a?(Hash)

    duration = payload['CallDuration'] || payload['call_duration']
    duration&.to_i
  end

  def payload_timestamp
    return unless payload.is_a?(Hash)

    ts = payload['Timestamp'] || payload['timestamp']
    return unless ts

    Time.zone.parse(ts).to_i
  rescue ArgumentError
    nil
  end
end
