class Copilot::V2::RecoveryJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    CopilotRun.where(status: 'queued').or(CopilotRun.where(status: 'running', lease_expires_at: ..Time.current)).find_each do |run|
      Copilot::V2::RunJob.perform_later(run.id)
    end
  end
end
