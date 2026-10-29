class Captain::Copilot::ApprovalExpiryJob < ApplicationJob
  queue_as :default

  # Wakes the waiting turn when the agent never decided. CopilotRun::Action#expire does nothing once the action is decided.
  def perform(run_id)
    CopilotRun::Action.find_by(id: run_id)&.expire
  end
end
