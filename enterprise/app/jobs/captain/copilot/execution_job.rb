class Captain::Copilot::ExecutionJob < ApplicationJob
  queue_as :default

  MAX_ATTEMPTS = 3

  def perform(run_id)
    run = CopilotRun.where(kind: 'chat', status: %w[queued running]).find_by(id: run_id)
    return unless run

    return self.class.set(wait: 5.seconds).perform_later(run.id) if run.behind_earlier_turn?

    token = run.claim
    self.class.set(wait_until: (run.lease_until || Time.current) + 30.seconds).perform_later(run.id)
    return unless token

    Captain::Copilot::ExecutionService.new(run, token).generate_response
  rescue Captain::Copilot::LeaseLostError
    nil
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
      run.update!(status: failed ? 'failed' : 'queued', attempts: attempts, error: exception.class.name, lease_token: nil, lease_until: nil)
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
