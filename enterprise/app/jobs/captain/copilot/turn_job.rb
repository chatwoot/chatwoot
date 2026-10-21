class Captain::Copilot::TurnJob < ApplicationJob
  include Captain::Copilot::LeasedJob

  # A new thread creates its first turn inside a transaction. Enqueued before the commit, the job can find no run and
  # leave the turn to the recovery job minutes later.
  self.enqueue_after_transaction_commit = true

  queue_as :default

  MAX_ATTEMPTS = 3

  # watched_token is set on the checks LeasedJob schedules.
  def perform(run_id, watched_token = nil)
    run = CopilotRun::Turn.claimable.find_by(id: run_id)
    return unless run

    return self.class.set(wait: 5.seconds).perform_later(run.id) if run.behind_earlier_turn?

    token = claim(run, watched_token)
    return unless token
    raise Captain::Copilot::LeaseExpiredError if run.taken_over?

    Captain::Copilot::TurnService.new(run, token).generate_response
  rescue Captain::Copilot::LeaseLostError
    nil
  rescue Captain::Copilot::LimitExceededError => e
    # Turning workflows off, running out of credits and the model-call limit are expected stops, so they are not reported.
    handle_failure(run, token, e)
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: run&.account).capture_exception
    handle_failure(run, token, e)
  end

  private

  def handle_failure(run, token, exception)
    return unless run && token

    run.with_lease(token) do
      attempts = run.attempts + 1
      failed = terminal_failure?(attempts, exception)
      run.release!(failed ? :failed : :queued, attempts: attempts, error: exception.class.name)
      if failed
        persist_failure(run, exception)
      else
        self.class.set(wait: 10.seconds).perform_later(run.id)
      end
    end
  rescue Captain::Copilot::LeaseLostError
    nil
  end

  def persist_failure(run, exception)
    content = if exception.is_a?(Captain::Copilot::LimitExceededError)
                exception.message
              else
                'I could not finish this request. Completed steps were saved.'
              end
    run.copilot_thread.copilot_messages.create!(message_type: :assistant, message: { run_id: run.id, content: content })
  end

  def terminal_failure?(attempts, exception)
    attempts >= MAX_ATTEMPTS || [Captain::Copilot::LimitExceededError, ArgumentError].any? { |type| exception.is_a?(type) }
  end
end
