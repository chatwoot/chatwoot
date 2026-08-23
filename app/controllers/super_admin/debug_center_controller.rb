class SuperAdmin::DebugCenterController < SuperAdmin::ApplicationController
  TABS = %w[audit runtime jobs llm].freeze
  LOG_LEVELS = %w[ALL INFO WARN ERROR FATAL].freeze
  DEFAULT_TAIL_BYTES = 1_500_000
  FEED_CAP = 200
  LEVEL_PATTERNS = {
    'INFO' => /\bINFO\b|\bseverity=INFO\b/i,
    'WARN' => /\bWARN(ING)?\b|\bseverity=WARN(ING)?\b/i,
    'ERROR' => /\bERROR\b|\bseverity=ERROR\b/i,
    'FATAL' => /\bFATAL\b|\bseverity=FATAL\b/i
  }.freeze

  def show
    @active_tab = params[:tab].presence_in(TABS) || 'audit'
    load_activity_feed if @active_tab == 'audit'
    load_runtime_logs if @active_tab == 'runtime'
    load_sidekiq_stats if @active_tab == 'jobs'
    load_llm_health if @active_tab == 'llm'
  end

  # Runs a live end-to-end LLM config check and re-renders the AI / LLM tab so an
  # admin can see which setting is broken without waiting for a real failure.
  def test
    @active_tab = 'llm'
    @llm_health = Captain::Llm::FailureLogger.check_config
    render :show
  end

  private

  def load_activity_feed
    @activity_feed = merged_activity_feed
    @entry_kinds = %w[general llm]
  end

  def merged_activity_feed
    entries = general_feed_entries + llm_feed_entries
    entries.sort_by { |entry| -entry[:created_at].to_i }.first(FEED_CAP)
  end

  def general_feed_entries
    return [] if params[:kind] == 'llm' || !audit_table_present?

    scope = apply_date_filter(AuditLog.order(created_at: :desc, id: :desc))
    scope.limit(FEED_CAP).map { |audit| audit_entry(audit) }
  end

  def llm_feed_entries
    return [] if params[:kind] == 'general' || !llm_log_table_present?

    scope = apply_date_filter(Captain::LlmFailureLog.ordered)
    scope.limit(FEED_CAP).map { |log| llm_entry(log) }
  end

  def apply_date_filter(scope)
    scope = scope.where('created_at >= ?', params[:from].to_date.beginning_of_day) if params[:from].present?
    scope = scope.where('created_at <= ?', params[:to].to_date.end_of_day) if params[:to].present?
    scope
  end

  def audit_entry(audit)
    {
      kind: 'general',
      created_at: audit.created_at,
      badge: audit.action,
      title: audit.audited_record_label.to_s,
      actor: audit.actor_label,
      meta: "id #{audit.auditable_id || audit.associated_id}".presence,
      detail: audit.audited_changes.present? ? audit.audited_changes.inspect.truncate(400) : nil
    }
  end

  def llm_entry(log)
    {
      kind: 'llm',
      created_at: log.created_at,
      badge: log.source,
      title: log.error_message.to_s,
      actor: log.model || log.provider || 'LLM',
      meta: [log.provider, log.error_code, log.endpoint].compact.join(' · ').presence,
      detail: log.error_class
    }
  end

  def load_runtime_logs
    @log_file = Rails.root.join('log', "#{Rails.env}.log")
    @log_level = params[:log_level].presence_in(LOG_LEVELS) || 'ALL'
    @log_lines = tail_log_file(@log_file, DEFAULT_TAIL_BYTES)
    @log_lines = filter_log_lines(@log_lines, @log_level) if @log_level != 'ALL'
  end

  def tail_log_file(path, bytes)
    return [] unless File.exist?(path)

    file_size = File.size(path)
    offset = [file_size - bytes, 0].max
    File.open(path, 'r') do |file|
      file.seek(offset)
      file.read
    end.lines.last(1000)
  end

  def filter_log_lines(lines, level)
    pattern = LEVEL_PATTERNS[level]
    lines.grep(pattern)
  end

  def load_sidekiq_stats
    stats = Sidekiq::Stats.new
    @sidekiq_metrics = sidekiq_metrics(stats)
    @sidekiq_queues = sidekiq_queue_metrics
    @sidekiq_retries = job_summaries(Sidekiq::RetrySet.new.take(20))
    @sidekiq_dead = job_summaries(Sidekiq::DeadSet.new.take(20))
  rescue Redis::CannotConnectError, Redis::BaseConnectionError
    @sidekiq_metrics = {}
    @sidekiq_queues = []
    @sidekiq_retries = []
    @sidekiq_dead = []
    @sidekiq_unreachable = true
  end

  def sidekiq_metrics(stats)
    {
      'Processed' => stats.processed,
      'Failed' => stats.failed,
      'Busy' => stats.workers_size,
      'Enqueued' => stats.enqueued,
      'Scheduled' => stats.scheduled_size,
      'Retries' => stats.retry_size,
      'Dead' => stats.dead_size
    }
  end

  def sidekiq_queue_metrics
    Sidekiq::Queue.all.map do |queue|
      { name: queue.name, size: queue.size, latency: queue.latency.round(2) }
    end
  end

  def job_summaries(jobs)
    jobs.map do |job|
      {
        class: job['class'],
        args: summarize_args(job['args']),
        error_message: job['error_message'],
        retry_count: job['retry_count'],
        failed_at: job['failed_at'],
        enqueued_at: job['enqueued_at']
      }
    end
  end

  def summarize_args(args)
    return nil if args.blank?

    args.inspect.truncate(200)
  end

  def load_llm_health
    @llm_health = Captain::Llm::FailureLogger.check_config
  rescue StandardError => e
    @llm_health = { error: e.message }
  end

  def audit_table_present?
    AuditLog.table_exists?
  end

  def llm_log_table_present?
    Captain::LlmFailureLog.table_exists?
  end
end
