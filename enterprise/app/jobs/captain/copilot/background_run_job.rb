# Lifecycle shared by the background runs a Copilot turn waits on, such as reviews and approved actions. Each job claims
# the run's lease, works through one step of records, re-queues itself until no records remain, and then hands its
# receipt back to the waiting tool call. Including jobs set RUN_KIND and implement process_step and incomplete?.
module Captain::Copilot::BackgroundRunJob
  STEP_SIZE = 25
  MAX_RUN_FAILURES = 3

  def perform(run_id)
    run = CopilotRun.where(kind: self.class::RUN_KIND, status: %w[queued running]).find_by(id: run_id)
    return unless run

    token = claim(run)
    return unless token

    process_step(run, token)
  rescue Captain::Copilot::LeaseLostError
    nil
  rescue Captain::Copilot::LimitExceededError => e
    finalize(run, token, error: e.message)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: run&.account).capture_exception
    handle_failure(run, token, e)
  end

  private

  def claim(run)
    token = run.claim
    self.class.set(wait_until: (run.lease_until || Time.current) + 30.seconds).perform_later(run.id)
    token
  end

  def continue_or_finalize(run, token)
    return finalize(run, token) if run.remaining_ids.empty?

    run.with_lease(token) { run.update!(status: 'queued', lease_token: nil, lease_until: nil) }
    self.class.perform_later(run.id)
  end

  def finalize(run, token, error: nil)
    receipt = run.with_lease(token) do
      incomplete = error || run.remaining_ids.any? || incomplete?(run)
      run.update!(status: incomplete ? 'incomplete' : 'completed', lease_token: nil, lease_until: nil, error: error)
      run.receipt
    end
    step = run.copilot_run_step
    step.copilot_run.resume_with(step, receipt)
  end

  def handle_failure(run, token, exception)
    return unless run && token

    attempts = run.with_lease(token) { run.update!(attempts: run.attempts + 1, error: exception.class.name) && run.attempts }
    # Outside the lease transaction, so the parent's wake-up is committed before its job can run.
    return finalize(run, token, error: exception.class.name) if attempts >= MAX_RUN_FAILURES

    run.with_lease(token) { run.update!(status: 'queued', lease_token: nil, lease_until: nil) }
    self.class.set(wait: 10.seconds).perform_later(run.id)
  rescue Captain::Copilot::LeaseLostError
    nil
  end
end
