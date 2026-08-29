class Voice::ReconcileSuppressedTerminationJob < ApplicationJob
  queue_as :default

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return unless call

    pending_status, pending_join = pending_callbacks(call)
    return if pending_status.blank? && pending_join.blank?

    if replay_join_first?(pending_status, pending_join)
      reconcile_pending_join!(call, pending_join)
      Voice::CallStatus::Manager.new(call: call).reconcile_suppressed_status!
    else
      Voice::CallStatus::Manager.new(call: call).reconcile_suppressed_status!
      reconcile_pending_join!(call, pending_join)
    end
  end

  private

  def pending_callbacks(call)
    call.with_lock do
      return [nil, nil] if call.terminal? || Voice::CallTerminationGuard.active?(call)

      Voice::CallTerminationGuard.clear_stale!(call)
      [Voice::CallTerminationGuard.pending_status(call), Voice::CallTerminationGuard.pending_join(call)]
    end
  end

  def replay_join_first?(pending_status, pending_join)
    return false if pending_join.blank?
    return true if pending_status.blank? || pending_status['timestamp'].blank?
    return false if pending_join['timestamp'].blank?

    pending_join['timestamp'].to_i <= pending_status['timestamp'].to_i
  end

  def reconcile_pending_join!(call, pending)
    return if pending.blank?

    Voice::Conference::Manager.new(
      call: call,
      event: 'join',
      participant_label: pending['participant_label'],
      participant_call_sid: pending['participant_call_sid'],
      participant_timestamp: pending['timestamp']
    ).process

    call.with_lock do
      Voice::CallTerminationGuard.clear_pending_join_if_matches!(call, pending)
    end
  end
end
