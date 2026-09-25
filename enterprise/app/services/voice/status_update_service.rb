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

  # Twilio's statuses in the order it fires them; callbacks can arrive out of order. Every
  # status that ends the call outranks the live ones, so none of them can follow it.
  PROVIDER_STATUS_ORDER = %w[queued initiated ringing in-progress].freeze
  TERMINAL_PROVIDER_STATUSES = %w[completed busy no-answer failed canceled].freeze

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
    provider_status = call_status.to_s.downcase
    return if provider_status.blank?

    # Callbacks for one call can run at the same time; the check and the write share the row lock
    call.with_lock do
      next if call.terminal? || call.provider_status == provider_status
      next if stale_provider_status?(call.provider_status, provider_status)

      call.update!(provider_status: provider_status)
      call.message&.touch # rubocop:disable Rails/SkipsModelValidations
    end
  end

  # A delayed callback for an earlier stage does not move the status backwards
  def stale_provider_status?(current, incoming)
    current_rank = provider_status_rank(current)
    incoming_rank = provider_status_rank(incoming)
    return false if current_rank.nil? || incoming_rank.nil?

    incoming_rank < current_rank
  end

  def provider_status_rank(status)
    return PROVIDER_STATUS_ORDER.size if TERMINAL_PROVIDER_STATUSES.include?(status)

    PROVIDER_STATUS_ORDER.index(status)
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
