# Backstop for a worker that died between committing a run's state and enqueuing the job that continues it. Jobs claim
# runs under a row lock, so enqueuing one that is already on its way is harmless.
class Captain::Copilot::RecoverRunsJob < ApplicationJob
  queue_as :scheduled_jobs

  STALE_AFTER = 5.minutes
  JOBS = { 'chat' => Captain::Copilot::ExecutionJob, 'review' => Captain::Copilot::ReviewJob }.freeze

  def perform
    stale = CopilotRun.where(updated_at: ...STALE_AFTER.ago)
    wake_waiting_runs(stale)
    requeue_runs(stale)
  end

  private

  # A review that finished without waking the chat run parked on its tool call.
  def wake_waiting_runs(stale)
    stale.where(kind: 'review', status: CopilotRun::TERMINAL_STATUSES).joins(:copilot_run_step)
         .where(copilot_run_steps: { status: 'running' }).find_each do |run|
      run.copilot_run_step.copilot_run.resume_with(run.copilot_run_step, run.receipt)
    end
  end

  # Runs left queued by a lost enqueue, or running on a lease that expired without a heartbeat to reclaim it.
  def requeue_runs(stale)
    stale.where(kind: JOBS.keys, status: %w[queued running]).where('lease_until IS NULL OR lease_until < ?', Time.current).find_each do |run|
      JOBS.fetch(run.kind).perform_later(run.id) unless run.kind == 'chat' && run.behind_earlier_turn?
    end
  end
end
