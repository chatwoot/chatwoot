class Voice::StatusUpdateService
  pattr_initialize [:account!, :call_sid!, :call_status, { payload: {} }]

  TWILIO_STATUS_MAP = {
    'queued' => 'ringing',
    'initiated' => 'ringing',
    'ringing' => 'ringing',
    'in-progress' => 'in-progress',
    'inprogress' => 'in-progress',
    'answered' => 'in-progress',
    'completed' => 'completed',
    'busy' => 'no-answer',
    'no-answer' => 'no-answer',
    'failed' => 'failed',
    'canceled' => 'failed'
  }.freeze

  def perform
    normalized_status = normalize_status(call_status)
    return if normalized_status.blank?

    conversation = account.conversations.find_by(identifier: call_sid)
    return unless conversation

    Voice::CallStatus::Manager.new(
      conversation: conversation,
      call_sid: call_sid
    ).process_status_update(
      normalized_status,
      duration: payload_duration,
      timestamp: payload_timestamp
    )
  end

  private

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
