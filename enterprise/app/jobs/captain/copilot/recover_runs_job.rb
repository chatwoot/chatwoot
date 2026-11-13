# Backstop for a worker that died between committing a run's state and enqueuing the job that continues it. Jobs claim
# runs under a row lock, so enqueuing one that is already on its way is harmless.
class Captain::Copilot::RecoverRunsJob < ApplicationJob
  queue_as :scheduled_jobs

  STALE_AFTER = 5.minutes
  # Conversation jobs wait on the low queue, which Sidekiq serves after every other queue, so a reviewing batch counts as
  # lost only after this long.
  STALLED_REVIEW_AFTER = 30.minutes
  JOBS = { CopilotRun::Turn => Captain::Copilot::TurnJob, CopilotRun::Review => Captain::Copilot::ReviewJob,
           CopilotRun::Action => Captain::Copilot::ActionJob }.freeze

  def perform
    stale = CopilotRun.where(updated_at: ...STALE_AFTER.ago)
    expire_overdue_approvals
    resume_turns_of_finished_runs(stale)
    take_back_stalled_reviews
    requeue_runs(stale)
  end

  private

  # An approval whose expiry job was lost would keep its turn waiting until the agent answered the card or wrote again.
  def expire_overdue_approvals
    CopilotRun::Action.awaiting_approval.where(created_at: ..CopilotRun::Action::APPROVAL_TTL.ago).find_each(&:expire)
  end

  # A review or action that finished without waking the turn parked on its tool call.
  def resume_turns_of_finished_runs(stale)
    stale.where(type: [CopilotRun::Review, CopilotRun::Action].map(&:sti_name)).finished.joins(:copilot_tool_call)
         .merge(CopilotToolCall.running).find_each do |run|
      run.copilot_tool_call.copilot_run.resume_with(run.copilot_tool_call, run.summary)
    end
  end

  # A review whose conversation jobs stopped coming back, such as after a worker crashed. Every finished job updates the
  # run. The conversations not reviewed yet go into the next batch.
  def take_back_stalled_reviews
    CopilotRun::Review.reviewing.where(updated_at: ...STALLED_REVIEW_AFTER.ago).find_each do |run|
      run.take_back_reviews!
      Captain::Copilot::ReviewJob.perform_later(run.id)
    end
  end

  # Runs left queued by a lost enqueue, such as an approved action, or running on a lease that expired without a heartbeat
  # to reclaim it.
  def requeue_runs(stale)
    stale.where(type: JOBS.keys.map(&:sti_name)).claimable.where('lease_until IS NULL OR lease_until < ?', Time.current).find_each do |run|
      JOBS.fetch(run.class).perform_later(run.id) unless run.is_a?(CopilotRun::Turn) && run.behind_earlier_turn?
    end
  end
end
