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

  # Twilio callbacks can arrive out of order.
  PROVIDER_STATUS_ORDER = %w[queued initiated ringing in-progress].freeze
  ACTIVE_PROVIDER_STATUSES = %w[in-progress inprogress answered].freeze
  TERMINAL_PROVIDER_STATUSES = %w[completed busy no-answer failed canceled].freeze

  def perform
    normalized_status = normalize_status(call_status)
    return if normalized_status.blank?

    call = Call.where(account_id: account.id).find_by(provider: :twilio, provider_call_id: call_sid)
    return unless call

    provider_status_changed = record_provider_status(call)
    status_before = call.status
    Voice::CallStatus::Manager.new(call: call).process_status_update(
      normalized_status,
      duration: payload_duration,
      timestamp: payload_timestamp
    )
    # The status manager broadcasts when the call status changes.
    call.message&.touch if provider_status_changed && call.status == status_before # rubocop:disable Rails/SkipsModelValidations
  end

  private

  # Provider status distinguishes queued, initiated, and ringing for outbound clients.
  def record_provider_status(call)
    provider_status = call_status.to_s.downcase
    return false if provider_status.blank?

    call.with_lock do
      next false if call.provider_status == provider_status || !provider_status_recordable?(call)
      next false if stale_provider_status?(call.provider_status, provider_status)

      call.merge_meta!('provider_status' => provider_status)
      true
    end
  end

  def provider_status_recordable?(call)
    !call.terminal? || call.meta&.dig('unanswered_by_failed_join').present?
  end

  def stale_provider_status?(current, incoming)
    current_rank = provider_status_rank(current)
    incoming_rank = provider_status_rank(incoming)
    return false if current_rank.nil? || incoming_rank.nil?

    incoming_rank < current_rank
  end

  def provider_status_rank(status)
    return PROVIDER_STATUS_ORDER.size if TERMINAL_PROVIDER_STATUSES.include?(status)
    return PROVIDER_STATUS_ORDER.index('in-progress') if ACTIVE_PROVIDER_STATUSES.include?(status)

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
