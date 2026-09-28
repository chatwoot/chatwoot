class ConversationMonitors::Update
  def initialize(monitor, attributes, collection_version: nil)
    @monitor = monitor
    @attributes = attributes
    @collection_version = collection_version
  end

  def perform
    # Match the scan/resume lock order before changing their collection version.
    ConversationMonitors::Monitor.transaction do
      @monitor.scans.order(:id).lock.load
      @monitor.with_lock { update_monitor }
    end
    ConversationMonitors::Scheduler.start_recheck(@monitor.id, @monitor.recheck_requested_at) if @condition_changed
    ConversationMonitors::BroadcastJob.schedule(@monitor.id)
    @monitor
  end

  private

  def update_monitor
    previous_version = @monitor.collection_version
    @monitor.assign_attributes(@attributes.slice('name', 'condition'))
    @condition_changed = @monitor.condition_changed?
    validate!
    update_collection
    @monitor.recheck_requested_at = Time.current if @condition_changed
    @monitor.data_revision += 1
    @monitor.save!
    reset_evaluations(previous_version) if @condition_changed
  end

  def validate!
    return unless @attributes.key?('condition') && @collection_version != @monitor.collection_version

    raise CustomExceptions::MonitorParametersError, 'monitor_changed'
  end

  def update_collection
    @monitor.paused_at ||= Time.current if @attributes['paused']
    @monitor.collection_version += 1 if @condition_changed || @monitor.paused_at_changed?
  end

  # Membership and scan versions change atomically with the definition. In-flight
  # provider results for the previous version cannot restore the old matches.
  # rubocop:disable Rails/SkipsModelValidations
  def reset_evaluations(previous_version)
    @monitor.evaluations.where.not(status: 'skipped').update_all(
      status: 'pending', score: nil, model: nil, error_code: nil, matched_at: nil, evaluated_at: nil,
      requested_version: @monitor.collection_version, updated_at: Time.current
    )
    @monitor.scans.where(collection_version: previous_version).update_all(
      collection_version: @monitor.collection_version, updated_at: Time.current
    )
  end
  # rubocop:enable Rails/SkipsModelValidations
end
