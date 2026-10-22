class Captain::Copilot::ReviewJob < ApplicationJob
  include Captain::Copilot::LeasedJob
  include Captain::Copilot::ConversationAccess

  # A batch makes up to 50 model calls in a row, so it runs on low with Captain's other long jobs instead of holding the
  # workers that handle incoming messages.
  queue_as :low

  BATCH_SIZE = 25
  MAX_ATTEMPTS = 2
  MAX_RUN_FAILURES = 3

  # watched_token is set on the checks LeasedJob schedules.
  def perform(run_id, watched_token = nil)
    run = CopilotRun::Review.claimable.find_by(id: run_id)
    return unless run

    token = claim(run, watched_token)
    return unless token

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

  def process_batch(run, token)
    conversations = Captain::Copilot::ScreeningService.new(run, token).screen(accessible_batch(run, token))
    service = Captain::Copilot::ReviewService.new(run)
    conversations.each do |conversation|
      run.renew_lease(token)
      review(run, token, service, conversation)
    end
    # One update per batch, after screening and review, so the counts move in even steps.
    run.with_lease(token) { run.publish_progress }
    return finalize(run, token) if run.remaining_ids.empty? || run.left_this_turn <= 0

    run.with_lease(token) { run.release!(:queued) }
    self.class.perform_later(run.id)
  end

  def accessible_batch(run, token)
    ids = run.remaining_ids.first([BATCH_SIZE, run.left_this_turn].min)
    found = accessible_conversations(account: run.account, user: run.user).where(id: ids).index_by(&:id)
    run.with_lease(token) { (ids - found.keys).each { |id| record_error(run, id, 'Conversation is no longer accessible') } }
    # In the saved order, newest first, so a run that stops partway has reviewed the newest conversations.
    ids.filter_map { |id| found[id] }
  end

  def review(run, token, service, conversation)
    deep = run.findings.needs_more_history.exists?(conversation_id: conversation.id)
    attributes = service.review(conversation, deep: deep)
    if attributes[:status] == :needs_more_history && deep
      attributes = attributes.merge(status: :failed,
                                    error: 'The 50 messages read were insufficient')
    end
    run.with_lease(token) { save_result(run, conversation.id, attributes) }
  rescue Captain::Copilot::LeaseLostError, Captain::Copilot::LimitExceededError
    raise
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: run.account).capture_exception
    error = e.is_a?(ArgumentError) ? e.message : "Review failed (#{e.class.name})"
    run.with_lease(token) { record_error(run, conversation.id, error) }
  end

  def save_result(run, id, attributes)
    finding = run.findings.find_or_initialize_by(conversation_id: id)
    return if finding.reviewed?

    finding.update!(error: nil, **attributes, attempts: finding.attempts + 1)
  end

  def record_error(run, id, error)
    finding = run.findings.find_or_initialize_by(conversation_id: id)
    return if finding.reviewed?

    attempts = finding.attempts + 1
    finding.update!(status: attempts >= MAX_ATTEMPTS ? :failed : :awaiting_retry, error: error, attempts: attempts)
  end

  # The turn that started this review is parked on its tool call; the summary becomes that call's result.
  def finalize(run, token, error: nil)
    summary = run.with_lease(token) do
      incomplete = error || run.findings.failed.exists? || run.selection_truncated? || run.remaining_ids.any?
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
