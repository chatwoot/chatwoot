class Captain::Copilot::ReviewJob < ApplicationJob
  include Captain::Copilot::ConversationAccess

  queue_as :default

  STEP_SIZE = 25
  MAX_ATTEMPTS = 2
  MAX_RUN_FAILURES = 3

  def perform(run_id)
    run = CopilotRun.where(kind: 'review', status: %w[queued running]).find_by(id: run_id)
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

  def process_step(run, token)
    conversations = Captain::Copilot::ScreeningService.new(run, token).screen(accessible_step(run, token))
    run.with_lease(token) { run.publish_progress } if run.match.present?
    service = Captain::Copilot::ReviewService.new(run, token)
    conversations.each do |conversation|
      run.renew_lease(token)
      review(run, token, service, conversation)
    end
    run.with_lease(token) { run.publish_progress } if conversations.any?
    return finalize(run, token) if run.remaining_ids.empty?

    run.with_lease(token) { run.update!(status: 'queued', lease_token: nil, lease_until: nil) }
    self.class.perform_later(run.id)
  end

  def accessible_step(run, token)
    ids = run.remaining_ids.first(STEP_SIZE)
    conversations = accessible_conversations(account: run.account, user: run.user).where(id: ids).to_a
    run.with_lease(token) { (ids - conversations.map(&:id)).each { |id| record_error(run, id, 'Conversation is no longer accessible') } }
    conversations
  end

  def review(run, token, service, conversation)
    deep = run.findings.exists?(conversation_id: conversation.id, status: 'more_history')
    attributes = service.analyze(conversation, deep: deep)
    attributes = attributes.merge(status: 'error', error: 'The last 50 messages were insufficient') if attributes[:status] == 'more_history' && deep
    run.with_lease(token) { save_result(run, conversation.id, attributes) }
  rescue Captain::Copilot::LeaseLostError, Captain::Copilot::LimitExceededError
    raise
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: run.account).capture_exception
    error = e.is_a?(ArgumentError) ? e.message : "Analysis failed (#{e.class.name})"
    run.with_lease(token) { record_error(run, conversation.id, error) }
  end

  def save_result(run, id, attributes)
    finding = run.findings.find_or_initialize_by(conversation_id: id)
    return if finding.status == 'resolved'

    finding.update!(error: nil, **attributes, attempts: finding.attempts + 1)
  end

  def record_error(run, id, error)
    finding = run.findings.find_or_initialize_by(conversation_id: id)
    return if finding.status == 'resolved'

    attempts = finding.attempts + 1
    finding.update!(status: attempts >= MAX_ATTEMPTS ? 'error' : 'retry', error: error, attempts: attempts)
  end

  # The chat run that started this review is parked on its tool call; the receipt becomes that call's result.
  def finalize(run, token, error: nil)
    receipt = run.with_lease(token) do
      incomplete = error || run.findings.exists?(status: 'error') || run.context['selection_truncated']
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
