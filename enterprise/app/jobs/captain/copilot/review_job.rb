class Captain::Copilot::ReviewJob < ApplicationJob
  include Captain::Copilot::ConversationAccess

  queue_as :default

  STEP_SIZE = 25
  MAX_ATTEMPTS = 2
  MAX_RUN_FAILURES = 3

  def perform(run_id)
    run = CopilotRun.where(kind: 'review', status: %w[queued running]).find_by(id: run_id)
    return unless run
    return self.class.set(wait: 5.seconds).perform_later(run.id) unless run.parent_run.parent_run.terminal?

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
    service = Captain::Copilot::ReviewService.new(run, token)
    run.with_lease(token) { run.publish_progress }
    run.remaining_ids.first(STEP_SIZE).each_slice(Captain::Copilot::ReviewService::BATCH_SIZE) do |ids|
      run.renew_lease(token)
      process_batch(run, token, service, ids)
      run.with_lease(token) { run.publish_progress }
    end
    return finalize(run, token) if run.remaining_ids.empty?

    run.with_lease(token) { run.update!(status: 'queued', lease_token: nil, lease_until: nil) }
    self.class.perform_later(run.id)
  end

  def process_batch(run, token, service, ids)
    rows = accessible_conversations(account: run.account, user: run.user).where(id: ids).to_a
    mark_inaccessible(run, token, ids - rows.map(&:id))
    return if rows.empty?

    deep_ids = run.findings.where(conversation_id: rows.map(&:id), status: 'more_history').pluck(:conversation_id)
    results = service.analyze(rows, deep_ids: deep_ids)
    run.with_lease(token) { save_results(run, results, deep_ids) }
  rescue Captain::Copilot::LeaseLostError, Captain::Copilot::LimitExceededError
    raise
  rescue StandardError => e
    record_batch_error(run, token, ids, e)
  end

  def record_batch_error(run, token, ids, exception)
    ChatwootExceptionTracker.new(exception, account: run.account).capture_exception
    error = exception.is_a?(ArgumentError) ? exception.message : "Analysis failed (#{exception.class.name})"
    run.with_lease(token) { ids.each { |id| record_error(run, id, error) } }
  end

  def mark_inaccessible(run, token, ids)
    run.with_lease(token) { ids.each { |id| record_error(run, id, 'Conversation is no longer accessible') } }
  end

  def save_results(run, results, deep_ids)
    results.each do |id, attributes|
      attributes[:error] = nil
      if attributes[:status] == 'more_history' && deep_ids.include?(id)
        attributes[:status] = 'error'
        attributes[:error] = 'The last 50 messages were insufficient'
      end
      finding = run.findings.find_or_initialize_by(conversation_id: id)
      next if finding.status == 'resolved'

      finding.update!(**attributes, attempts: finding.attempts + 1)
    end
  end

  def record_error(run, id, error)
    finding = run.findings.find_or_initialize_by(conversation_id: id)
    return if finding.status == 'resolved'

    attempts = finding.attempts + 1
    finding.update!(status: attempts >= MAX_ATTEMPTS ? 'error' : 'retry', error: error, attempts: attempts)
  end

  def finalize(run, token, error: nil)
    run.with_lease(token) do
      incomplete = error || run.findings.exists?(status: 'error') || run.context['selection_truncated']
      run.update!(status: incomplete ? 'incomplete' : 'completed', lease_token: nil, lease_until: nil, error: error)
      run.publish_progress
      presentation = Captain::Copilot::PresentationService.new(run).table
      run.copilot_thread.copilot_messages.create!(message_type: :assistant, message: { run_id: run.id, content: presentation[:content] })
    end
  end

  def handle_failure(run, token, exception)
    return unless run && token

    run.with_lease(token) do
      attempts = run.attempts + 1
      run.update!(attempts: attempts, error: exception.class.name)
      return finalize(run, token, error: exception.class.name) if attempts >= MAX_RUN_FAILURES

      run.update!(status: 'queued', lease_token: nil, lease_until: nil)
      self.class.set(wait: 10.seconds).perform_later(run.id)
    end
  rescue Captain::Copilot::LeaseLostError
    nil
  end
end
