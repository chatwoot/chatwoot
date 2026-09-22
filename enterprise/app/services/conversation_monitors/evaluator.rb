class ConversationMonitors::Evaluator
  LEASE_DURATION = 2.minutes
  MAX_ATTEMPTS = 5
  QUESTIONS_PER_REQUEST = 20

  def initialize(work)
    @work = work
    @errors = []
  end

  def perform
    return unless ConversationMonitors::Configuration.enabled?(@work.account)
    return unless @work.account.conversation_monitors.active.exists?

    @snapshot = claim
    return unless @snapshot

    @monitors = pending_monitors
    @snapshot[:monitor_versions] = @monitors.pluck(:id, :collection_version).to_h
    evaluate if @monitors.any?
    finish
    ConversationMonitors::ProcessJob.set(wait_until: @work.due_at).perform_later(@work.conversation_id) if @work.due_at
    @monitors.each { |monitor| ConversationMonitors::BroadcastJob.schedule(monitor.id) }
  end

  private

  def claim
    @work.with_lock do
      return if @work.due_at.nil? || @work.due_at > Time.current || @work.lease_expires_at&.future?

      token = SecureRandom.uuid
      @work.update!(lease_token: token, lease_expires_at: LEASE_DURATION.from_now)
      { token: token, revision: @work.revision, generation: @work.generation,
        full_history: @work.full_history_revision > @work.processed_revision }
    end
  end

  def pending_monitors
    evaluations = ConversationMonitors::Evaluation.where(conversation_id: @work.conversation_id).index_by(&:monitor_id)
    @work.account.conversation_monitors.active.reject do |monitor|
      evaluation = evaluations[monitor.id]
      !monitor.eligible_activity?(@work, evaluation) || (evaluation && (evaluation.status == 'matched' ||
        (evaluation.status == 'unmatched' && evaluation.input_revision >= @snapshot[:revision])))
    end
  end

  def evaluate
    message_limit = ConversationMonitors::Configuration::LIVE_MESSAGE_LIMIT unless @snapshot[:full_history]
    state = ConversationMonitors::ContextBuilder.new(@work.conversation, message_limit: message_limit).build
    @monitors.group_by(&:model).each_value do |monitors|
      monitors.each_slice(QUESTIONS_PER_REQUEST) { |batch| evaluate_batch(state, batch) }
    end
  rescue CustomExceptions::MonitorEvaluationError => e
    record_error(@monitors, e)
  end

  def evaluate_batch(state, monitors)
    return unless current_input?

    monitors = monitors.select { |monitor| current_monitor?(monitor) }
    return if monitors.empty?

    response = ConversationMonitors::JevClient.new(account_id: @work.account_id).evaluate(state: state, monitors: monitors)
    monitors.each do |monitor|
      score = ConversationMonitors::JevClient.score(response['answers'][monitor.id.to_s])
      writer.write(monitor, score: score, model: response['model'])
    rescue CustomExceptions::MonitorEvaluationError => e
      record_error([monitor], e)
    end
  rescue CustomExceptions::MonitorEvaluationError => e
    handle_batch_error(state, monitors, e)
  end

  def handle_batch_error(state, monitors, error)
    return record_error(monitors, error) unless error.code == 'context_limit' && monitors.size > 1

    # The client rejects oversized payloads before reserving a credit or making a request.
    monitors.each_slice((monitors.size / 2.0).ceil) { |batch| evaluate_batch(state, batch) }
  end

  def current_input?
    ConversationMonitors::Configuration.enabled?(@work.account.reload) &&
      @work.reload.generation == @snapshot[:generation] && @work.lease_token == @snapshot[:token]
  end

  def current_monitor?(monitor)
    monitor.reload.collecting? && monitor.collection_version == @snapshot[:monitor_versions].fetch(monitor.id)
  end

  def record_error(monitors, error)
    @errors << error
    monitors.each { |monitor| writer.write(monitor, error: error) }
  end

  def writer
    @writer ||= ConversationMonitors::ResultWriter.new(@work, @snapshot)
  end

  def finish
    @work.with_lock do
      return unless @work.lease_token == @snapshot[:token]

      unless ConversationMonitors::Configuration.enabled?(@work.account.reload)
        @work.update!(lease_token: nil, lease_expires_at: nil)
        return
      end

      newer_input = newer_input?
      retry_error = next_retry_error
      @work.assign_attributes(lease_token: nil, lease_expires_at: nil, error_code: (retry_error || @errors.first)&.code)
      update_progress(retry_error)
      @work.due_at = next_due(newer_input, retry_error)
      @work.attempts += 1 unless newer_input
      @work.save!
    end
  end

  def next_retry_error
    @errors.find { |error| error.code == 'monthly_limit' } || @errors.find(&:retryable?)
  end

  def update_progress(error)
    if error&.code == 'monthly_limit'
      @work.full_history_revision = @work.revision
    elsif @errors.empty?
      @work.processed_revision = @snapshot[:revision]
    end
  end

  def next_due(newer_input, error)
    return error.retry_after.seconds.from_now if error&.code == 'monthly_limit'

    return 3.seconds.from_now if newer_input
    return unless error
    return if @work.attempts >= MAX_ATTEMPTS && %w[rate_limit budget_limit].exclude?(error.code)

    delay = [error.retry_after.to_i, (5 * (2**[@work.attempts, 8].min)) + rand(5)].max
    delay.seconds.from_now
  end

  def newer_input?
    return true if @work.revision > @snapshot[:revision]

    @monitors.any? do |monitor|
      monitor.reload.collecting? && monitor.collection_version != @snapshot[:monitor_versions].fetch(monitor.id)
    end
  end
end
