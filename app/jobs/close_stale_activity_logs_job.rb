class CloseStaleActivityLogsJob < ApplicationJob
  queue_as :low

  def perform
    AgentActivity::ActivityTracker.close_stale_logs
  end
end
