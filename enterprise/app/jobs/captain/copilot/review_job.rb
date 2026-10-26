class Captain::Copilot::ReviewJob < ApplicationJob
  include Captain::Copilot::BackgroundRunJob
  include Captain::Copilot::ConversationAccess

  # A batch makes up to 50 model calls in a row, so it runs on low with Captain's other long jobs instead of holding the
  # workers that handle incoming messages.
  queue_as :low

  RUN_CLASS = CopilotRun::Review
  MAX_ATTEMPTS = 2
  # Conversations reviewed at once. Each review waits seconds on the model, so a few at a time cut the wait without
  # sending a burst of requests.
  PARALLEL_REVIEWS = 5

  private

  # The card shows up before screening, which is the longest wait, and then moves after every group of reviews.
  def process_batch(run, token)
    run.with_lease(token) { run.publish_progress }
    conversations = Captain::Copilot::ScreeningService.new(run, token).screen(accessible_batch(run, token))
    run.with_lease(token) { run.publish_progress }
    service = Captain::Copilot::ReviewService.new(run)
    conversations.each_slice(PARALLEL_REVIEWS) do |slice|
      run.renew_lease(token)
      review_slice(run, token, service, slice)
      run.with_lease(token) { run.publish_progress }
    end
    # A review stops at its turn limit; continue_review raises it when the agent asks for the next batch.
    return finalize(run, token) if run.left_this_turn <= 0

    continue_or_finalize(run, token)
  end

  def accessible_batch(run, token)
    ids = run.remaining_ids.first([BATCH_SIZE, run.left_this_turn].min)
    found = accessible_conversations(account: run.account, user: run.user).where(id: ids).index_by(&:id)
    run.with_lease(token) { (ids - found.keys).each { |id| record_error(run, id, 'Conversation is no longer accessible') } }
    # In the saved order, newest first, so a run that stops partway has reviewed the newest conversations.
    ids.filter_map { |id| found[id] }
  end

  # The requests are built and the results saved on this thread, in the batch's order. Only the model calls run on
  # threads of their own, and they never touch the database, so they take no connection from the pool.
  def review_slice(run, token, service, slice)
    requests = slice.filter_map do |conversation|
      reviewing(run, token, conversation) do
        service.prepare(conversation, deep: deep?(run, conversation))
      end
    end
    threads = requests.map { |request| Thread.new { Rails.application.executor.wrap { ask(service, request) } } }
    # A thread that loads a class while this one waits would otherwise deadlock in development.
    answered = ActiveSupport::Dependencies.interlock.permit_concurrent_loads { threads.map(&:value) }
    answered.each do |request|
      reviewing(run, token, request[:conversation]) do
        raise request[:error] if request[:error]

        save_review(run, token, request[:conversation].id, service.finish(request), request[:deep])
      end
    end
  end

  def deep?(run, conversation)
    run.findings.needs_more_history.exists?(conversation_id: conversation.id)
  end

  # A failed model call comes back as the request's error, so the job's thread records it with the others.
  def ask(service, request)
    service.ask(request)
  rescue StandardError => e
    request.merge(error: e)
  end

  def save_review(run, token, id, attributes, deep)
    if attributes[:status] == :needs_more_history && deep
      attributes = attributes.merge(status: :failed,
                                    error: 'The 50 messages read were insufficient')
    end
    run.with_lease(token) { save_result(run, id, attributes) }
  end

  # A failure is recorded on the conversation, so the rest of the batch goes on. Losing the lease or reaching the credit
  # limit stops the whole run.
  def reviewing(run, token, conversation)
    yield
  rescue Captain::Copilot::LeaseLostError, Captain::Copilot::LimitExceededError
    raise
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: run.account).capture_exception
    error = e.is_a?(ArgumentError) ? e.message : "Review failed (#{e.class.name})"
    run.with_lease(token) { record_error(run, conversation.id, error) }
    nil
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

  def incomplete?(run)
    run.findings.failed.exists? || run.selection_truncated?
  end
end
