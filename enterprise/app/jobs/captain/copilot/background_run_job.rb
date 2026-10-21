# Lifecycle shared by the background runs a Copilot turn waits on, such as reviews and approved actions. Each job claims
# the run's lease, works through one batch of records, re-queues itself until no records remain, and then hands its
# summary back to the waiting tool call. Including jobs set RUN_CLASS and implement process_batch and incomplete?.
module Captain::Copilot::BackgroundRunJob
  include Captain::Copilot::LeasedJob

  BATCH_SIZE = 25
  MAX_RUN_FAILURES = 3

  # watched_token is set on the checks LeasedJob schedules.
  def perform(run_id, watched_token = nil)
    run = self.class::RUN_CLASS.claimable.find_by(id: run_id)
    return unless run

    token = claim(run, watched_token)
    return unless token
    raise Captain::Copilot::LeaseExpiredError if run.taken_over?

    process_batch(run, token)
  rescue Captain::Copilot::LeaseLostError
    nil
  rescue Captain::Copilot::LimitExceededError => e
    finalize(run, token, error: e.message)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: run&.account).capture_exception
    handle_failure(run, token, e)
  end

  private

  def continue_or_finalize(run, token)
    return finalize(run, token) if run.remaining_ids.empty?

    run.with_lease(token) { run.release!(:queued) }
    self.class.perform_later(run.id)
  end

  def finalize(run, token, error: nil)
    summary = run.with_lease(token) do
      incomplete = error || run.remaining_ids.any? || incomplete?(run)
      run.release!(incomplete ? :incomplete : :completed, error: error)
      run.summary
    end
    tool_call = run.copilot_tool_call
    tool_call.copilot_run.resume_with(tool_call, summary)
  end

  def handle_failure(run, token, exception)
    return unless run && token

    attempts = run.with_lease(token) { run.update!(attempts: run.attempts + 1, error: exception.class.name) && run.attempts }
    # Outside the lease transaction, so the parent's wake-up is committed before its job can run.
    return finalize(run, token, error: exception.class.name) if attempts >= MAX_RUN_FAILURES

    run.with_lease(token) { run.release!(:queued) }
    self.class.set(wait: 10.seconds).perform_later(run.id)
  rescue Captain::Copilot::LeaseLostError
    nil
  end
end
