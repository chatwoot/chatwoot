class Voice::ReconcileSuppressedTerminationJob < ApplicationJob
  queue_as :default

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return unless call

    Voice::CallStatus::Manager.new(call: call).reconcile_suppressed_status!
    reconcile_pending_join!(call)
  end

  private

  def reconcile_pending_join!(call)
    pending = nil
    call.with_lock do
      next if call.terminal? || Voice::CallTerminationGuard.active?(call)

      Voice::CallTerminationGuard.clear_stale!(call)
      pending = Voice::CallTerminationGuard.pending_join(call)
      Voice::CallTerminationGuard.clear_pending_join!(call) if pending.present?
    end
    return if pending.blank?

    Voice::Conference::Manager.new(
      call: call,
      event: 'join',
      participant_label: pending['participant_label'],
      participant_call_sid: pending['participant_call_sid']
    ).process
  end
end
