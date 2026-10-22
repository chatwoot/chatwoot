# Backstop for a worker that died between committing a run's state and enqueuing the job that continues it. Jobs claim
# runs under a row lock, so enqueuing one that is already on its way is harmless.
class Captain::Copilot::RecoverRunsJob < ApplicationJob
  queue_as :scheduled_jobs

  STALE_AFTER = 5.minutes
  JOBS = { CopilotRun::Turn => Captain::Copilot::TurnJob, CopilotRun::Review => Captain::Copilot::ReviewJob }.freeze

  def perform
    stale = CopilotRun.where(updated_at: ...STALE_AFTER.ago)
    resume_turns_of_finished_runs(stale)
    requeue_runs(stale)
  end

  private

  # A review that finished without waking the turn parked on its tool call.
  def resume_turns_of_finished_runs(stale)
    stale.where(type: CopilotRun::Review.sti_name).finished.joins(:copilot_tool_call).merge(CopilotToolCall.running).find_each do |run|
      run.copilot_tool_call.copilot_run.resume_with(run.copilot_tool_call, run.summary)
    end
  end

  # Runs left queued by a lost enqueue, or running on a lease that expired without a heartbeat to reclaim it.
  def requeue_runs(stale)
    stale.where(type: JOBS.keys.map(&:sti_name)).claimable.where('lease_until IS NULL OR lease_until < ?', Time.current).find_each do |run|
      JOBS.fetch(run.class).perform_later(run.id) unless run.is_a?(CopilotRun::Turn) && run.behind_earlier_turn?
    end
  end
end
