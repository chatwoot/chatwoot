class Voice::ReconcileSuppressedTerminationJob < ApplicationJob
  queue_as :default

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return unless call

    Voice::CallStatus::Manager.new(call: call).reconcile_suppressed_terminal!
  end
end
