class Voice::CallStatus::Manager
  pattr_initialize [:call!]

  def process_status_update(status, duration: nil, timestamp: nil, allow_during_termination: false)
    return unless Call::STATUSES.include?(status)

    applied = false
    deferred = false
    call.with_lock do
      next if call.status == status
      next if Call::TERMINAL_STATUSES.include?(call.status)

      if termination_blocks?(allow_during_termination)
        if Call::TERMINAL_STATUSES.include?(status)
          Voice::CallTerminationGuard.persist_pending_terminal!(
            call,
            status: status,
            duration: duration,
            timestamp: timestamp
          )
          deferred = true
        end
        next
      end

      apply_call_updates!(status, duration: duration, timestamp: timestamp)
      applied = true
    end

    schedule_reconciliation if deferred
    publish_update if applied
  end

  def reconcile_suppressed_terminal!
    applied = false
    call.with_lock do
      next if Call::TERMINAL_STATUSES.include?(call.status)
      next if Voice::CallTerminationGuard.active?(call)

      pending = Voice::CallTerminationGuard.pending_terminal(call)
      next if pending.blank?

      Voice::CallTerminationGuard.clear_stale!(call)
      apply_call_updates!(
        pending['status'],
        duration: pending['duration'],
        timestamp: pending['timestamp']
      )
      Voice::CallTerminationGuard.clear_pending_terminal!(call)
      applied = true
    end
    publish_update if applied
  end

  private

  def termination_blocks?(allow_during_termination)
    return false if allow_during_termination

    Voice::CallTerminationGuard.clear_stale!(call)
    Voice::CallTerminationGuard.active?(call)
  end

  def schedule_reconciliation
    Voice::ReconcileSuppressedTerminationJob.set(wait: Voice::CallTerminationGuard::STALE_AFTER + 5.seconds).perform_later(call.id)
  end

  def publish_update
    call.conversation.update!(last_activity_at: Time.zone.now)
    call.message&.touch # rubocop:disable Rails/SkipsModelValidations
  end

  def apply_call_updates!(status, duration:, timestamp:)
    attrs = { status: status }
    ts = timestamp || now_seconds

    if status == 'in_progress'
      started_at = Time.zone.at(ts)
      attrs[:started_at] = started_at if call.started_at.nil? || started_at < call.started_at
    elsif Call::TERMINAL_STATUSES.include?(status)
      call.ended_at = ts
      attrs[:meta] = call.meta
      attrs[:duration_seconds] = resolved_duration(duration, ts)
    end

    call.update!(attrs)
  end

  def resolved_duration(provided_duration, timestamp)
    return provided_duration if provided_duration
    return unless call.started_at

    [timestamp - call.started_at.to_i, 0].max
  end

  def now_seconds
    Time.zone.now.to_i
  end
end
