class ConversationMonitors::Evaluator
  LEASE_DURATION = 2.minutes
  MAX_ATTEMPTS = 5
  QUESTIONS_PER_REQUEST = 20
  LIMIT_RETRY_JITTER = 4.hours

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
      live_activity_at = @work.live_activity_at if @work.live_activity_revision > @work.processed_revision
      { token: token, revision: @work.revision, generation: @work.generation,
        full_history: @work.full_history_revision > @work.processed_revision,
        live_activity_at: live_activity_at }
    end
  end

  def pending_monitors
    evaluations = ConversationMonitors::Evaluation.where(conversation_id: @work.conversation_id).index_by(&:monitor_id)
    @work.account.conversation_monitors.active.reject do |monitor|
      evaluation = evaluations[monitor.id]
      !monitor.eligible_activity?(@work.activity_at, evaluation) || (evaluation && (evaluation.status == 'matched' ||
        (evaluation.status == 'unmatched' && evaluation.input_revision >= @snapshot[:revision])))
    end
  end

  def evaluate
    message_limit = ConversationMonitors::Configuration::LIVE_MESSAGE_LIMIT unless @snapshot[:full_history]
    primary_state, fallback_state, result_writer = evaluation_states(message_limit)
    @monitors.group_by { |monitor| ConversationMonitors::DecisionService.resolve_model(monitor.model) }.each_value do |monitors|
      monitors.each_slice(QUESTIONS_PER_REQUEST) do |batch|
        evaluate_batch(primary_state, batch, fallback_state: fallback_state, result_writer: result_writer)
      end
    end
  rescue CustomExceptions::MonitorEvaluationError => e
    record_error(@monitors, e)
  end

  def evaluation_states(message_limit)
    state = ConversationMonitors::ContextBuilder.new(@work.conversation, message_limit: message_limit).build
    return [state, nil, historical_writer] unless @snapshot[:live_activity_at]

    action_state = build_action_state(message_limit)
    return [state, nil, historical_writer] unless action_state

    # Generated replies can arrive before the debounce fires. Check eligible messages for an action first,
    # then use the full transcript for reporting when only the generated reply makes the monitor match.
    [action_state, action_state == state ? nil : state, writer]
  end

  def build_action_state(message_limit)
    ConversationMonitors::ContextBuilder.new(
      @work.conversation,
      message_limit: message_limit,
      message_cutoff_at: @snapshot[:live_activity_at],
      exclude_automation_messages: true
    ).build
  rescue CustomExceptions::MonitorEvaluationError => e
    raise unless e.code == 'no_text'

    nil
  end

  def evaluate_batch(state, monitors, fallback_state: nil, result_writer: writer)
    return unless current_input?

    monitors = monitors.select { |monitor| current_monitor?(monitor) }
    return if monitors.empty?

    response = ConversationMonitors::DecisionService.new(account_id: @work.account_id, conversation_id: @work.conversation.display_id)
                                                    .evaluate(state: state, monitors: monitors)
    fallback_monitors = write_answers(response, monitors, fallback_state, result_writer)
    evaluate_batch(fallback_state, fallback_monitors, result_writer: historical_writer) if fallback_monitors.any?
  rescue CustomExceptions::MonitorEvaluationError => e
    handle_batch_error(state, monitors, e, fallback_state: fallback_state, result_writer: result_writer)
  end

  def write_answers(response, monitors, fallback_state, result_writer)
    monitors.filter_map do |monitor|
      score = ConversationMonitors::DecisionService.score(response['answers'][monitor.id.to_s])
      next monitor if fallback_state && score < monitor.threshold

      result_writer.write(monitor, score: score, model: response['model'])
      nil
    rescue CustomExceptions::MonitorEvaluationError => e
      record_error([monitor], e)
      nil
    end
  end

  def handle_batch_error(state, monitors, error, fallback_state:, result_writer:)
    return record_error(monitors, error) unless error.code == 'context_limit' && monitors.size > 1

    # The client rejects oversized payloads before reserving a credit or making a request.
    monitors.each_slice((monitors.size / 2.0).ceil) do |batch|
      evaluate_batch(state, batch, fallback_state: fallback_state, result_writer: result_writer)
    end
  end

  def current_input?
    ConversationMonitors::Configuration.enabled?(@work.account.reload) &&
      @work.reload.revision == @snapshot[:revision] && @work.generation == @snapshot[:generation] &&
      @work.lease_token == @snapshot[:token]
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

  def historical_writer
    @historical_writer ||= ConversationMonitors::ResultWriter.new(@work, @snapshot.merge(live_activity_at: nil))
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
    @errors.find { |error| error.code == 'monthly_limit' } ||
      @errors.find { |error| error.code == 'budget_limit' } ||
      @errors.find(&:retryable?)
  end

  def update_progress(error)
    if %w[monthly_limit budget_limit].include?(error&.code)
      @work.full_history_revision = @work.revision
    elsif @errors.empty?
      @work.processed_revision = @snapshot[:revision]
    end
  end

  def next_due(newer_input, error)
    return (retry_delay + rand(LIMIT_RETRY_JITTER.to_i)).seconds.from_now if %w[monthly_limit budget_limit].include?(error&.code)

    return 3.seconds.from_now if newer_input
    return unless error
    return if @work.attempts + 1 >= MAX_ATTEMPTS

    retry_delay.seconds.from_now
  end

  def retry_delay
    retry_after = @errors.select(&:retryable?).map { |batch_error| batch_error.retry_after.to_i }.max.to_i
    [retry_after, (5 * (2**[@work.attempts, 8].min)) + rand(5)].max
  end

  def newer_input?
    return true if @work.revision > @snapshot[:revision]

    @monitors.any? do |monitor|
      monitor.reload.collecting? && monitor.collection_version != @snapshot[:monitor_versions].fetch(monitor.id)
    end
  end
end
