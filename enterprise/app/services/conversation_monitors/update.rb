class ConversationMonitors::Update
  def initialize(monitor, attributes, collection_version: nil)
    @monitor = monitor
    @attributes = attributes
    @collection_version = collection_version
  end

  def perform
    # Match the scan/resume lock order before changing their collection version.
    @monitor.backfill.with_lock do
      @monitor.resumptions.where(mode: 'catch_up', cancelled_at: nil).order(:id).lock.load
      @monitor.with_lock { update_monitor }
    end
    ConversationMonitors::Scheduler.start_recheck(@monitor.id) if @condition_changed
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
    if @attributes.key?('condition') && @collection_version != @monitor.collection_version
      raise CustomExceptions::MonitorParametersError, 'monitor_changed'
    end
    return unless @condition_changed && (@monitor.archived_at || @attributes['archived'])

    raise CustomExceptions::MonitorParametersError, 'monitor_archived'
  end

  def update_collection
    @monitor.archived_at ||= Time.current if @attributes['archived']
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
    @monitor.resumptions.where(collection_version: previous_version).update_all(
      collection_version: @monitor.collection_version, updated_at: Time.current
    )
  end
  # rubocop:enable Rails/SkipsModelValidations
end
