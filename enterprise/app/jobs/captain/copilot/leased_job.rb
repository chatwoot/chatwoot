# Jobs that work on a Copilot run under its lease. The job that takes the lease schedules a check for just after the lease
# would expire, carrying its lease token. If that token still holds a live lease, the worker is alive and the check
# schedules the next one. If another token holds it, a newer job took over and watches the run itself, so the check stops.
# If the lease expired, the worker died, so the check claims the run and carries on. A run has one chain of checks, and a
# crashed run restarts about 30 seconds after its lease expires instead of waiting for RecoverRunsJob.
module Captain::Copilot::LeasedJob
  private

  def claim(run, watched_token)
    token = run.claim
    if token
      watch(run, token)
    elsif watched_token.present? && run.lease_token == watched_token
      watch(run, watched_token)
    end
    token
  end

  def watch(run, token)
    self.class.set(wait_until: run.lease_until + 30.seconds).perform_later(run.id, token)
  end
end
