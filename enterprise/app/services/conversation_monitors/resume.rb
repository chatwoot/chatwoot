class ConversationMonitors::Resume
  def initialize(monitor, mode:, collection_version:)
    @monitor = monitor
    @mode = mode
    @collection_version = collection_version
  end

  def perform
    @monitor.account.with_lock do
      # Scan jobs lock their cursor before requesting work or locking the monitor.
      @monitor.scans.order(:id).lock.load
      @monitor.with_lock do
        validate!
        resume_collection
      end
    end
    ConversationMonitors::Scheduler.start_scan(@scan.id) if @mode == 'catch_up'
    ConversationMonitors::Scheduler.start_recheck(@monitor.id, @monitor.recheck_requested_at) if @monitor.recheck_requested_at
    ConversationMonitors::BroadcastJob.schedule(@monitor.id)
    @monitor
  end

  private

  def validate!
    raise CustomExceptions::MonitorParametersError, 'invalid_parameters' unless %w[catch_up from_now].include?(@mode)
    raise CustomExceptions::MonitorParametersError, 'monitor_changed' unless @monitor.resumable? && @monitor.collection_version == @collection_version
    return if @monitor.account.conversation_monitors.active.count < ConversationMonitors::Configuration.max_monitors

    raise CustomExceptions::MonitorParametersError, 'monitor_limit'
  end

  # Bulk state transitions run under the monitor lock without instantiating its conversation-sized evaluation set.
  # rubocop:disable Rails/SkipsModelValidations
  def resume_collection
    now = Time.current
    paused_at = @monitor.paused_at
    @monitor.update!(paused_at: nil, resumed_at: now, collection_version: @monitor.collection_version + 1, data_revision: @monitor.data_revision + 1)
    cancel_unfinished_scans(now)
    unless @monitor.recheck_requested_at
      @monitor.evaluations.where(status: %w[pending error]).update_all(status: 'skipped', requested_version: nil, error_code: nil, updated_at: now)
    end
    @scan = @monitor.scans.create!(kind: @mode, started_at: paused_at, ended_at: now,
                                   collection_version: @monitor.collection_version, enumerated_at: @mode == 'from_now' ? now : nil)
  end

  def cancel_unfinished_scans(now)
    versions = @monitor.evaluations.where(status: %w[pending error]).select(:requested_version)
    scans = @monitor.scans.where(cancelled_at: nil).where.not(kind: 'from_now')
    scans.where(enumerated_at: nil).or(scans.where(collection_version: versions)).update_all(cancelled_at: now, updated_at: now)
  end
  # rubocop:enable Rails/SkipsModelValidations
end
