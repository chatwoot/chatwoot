class Voice::CallStatus::Manager
  pattr_initialize [:call!]

  def process_status_update(status, duration: nil, timestamp: nil)
    return unless Call::STATUSES.include?(status)

    # Guards run on the locked row, not the caller's copy, so a callback racing an agent hangup can't overwrite its outcome.
    call.with_lock do
      if late_answer?(status)
        record_late_answer!(timestamp)
      else
        next if keep_current_status?(status)

        apply_call_updates!(status, duration: duration, timestamp: timestamp)
      end
      call.conversation.update!(last_activity_at: Time.zone.now)
      # Bump updated_at so the message.updated dispatcher rebroadcasts with the fresh Call embedded.
      call.message&.touch # rubocop:disable Rails/SkipsModelValidations
    end
  end

  private

  # A delayed answer can correct a failed join's no-answer outcome.
  def late_answer?(status) = status == 'in_progress' && call.unanswered_by_failed_join?

  def record_late_answer!(timestamp)
    started = timestamp || now_seconds
    ended = call.ended_at&.to_i
    call.update!(status: 'failed', started_at: Time.zone.at(started), duration_seconds: ended && [ended - started, 0].max)
  end

  def keep_current_status?(status)
    call.status == status ||
      Call::TERMINAL_STATUSES.include?(call.status) ||
      (status == 'ringing' && call.in_progress?)
  end

  def apply_call_updates!(status, duration:, timestamp:)
    attrs = { status: status }
    ts = timestamp || now_seconds

    if status == 'in_progress'
      # Twilio can emit multiple in-progress updates (answered + in-progress, retries).
      # Keep the earliest timestamp so duration_seconds doesn't shift forward.
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
