class ConversationMonitors::Presenter
  def initialize(monitor)
    @monitor = monitor
    @backfill = monitor.backfill
  end

  def as_json
    {
      id: @monitor.id, name: @monitor.name, condition: @monitor.condition,
      created_at: @monitor.created_at.to_i, history_since: @monitor.history_since.to_i,
      archived_at: @monitor.archived_at&.to_i, data_revision: @monitor.data_revision,
      collection_version: @monitor.collection_version,
      # Report bounds are whole seconds; include matches created within the pause second.
      paused_at: @monitor.paused_at&.ceil&.to_i,
      last_evaluated_at: @monitor.evaluations.maximum(:evaluated_at)&.to_i,
      recent_count: @monitor.matched_conversations.where(created_at: ((@monitor.paused_at || Time.current) - 7.days)..).count,
      processing: processing
    }
  end

  private

  def processing
    @counts = @monitor.evaluations.group(:status).count
    @historical_completed = historical_completed
    @historical_eligible = @backfill.population.count
    @resumption = @monitor.resumptions.find_by(collection_version: @monitor.collection_version)
    @has_gaps = @monitor.resumptions.incomplete.exists?
    {
      state: state, evaluated: @historical_completed,
      eligible: @historical_eligible, enumerated: @backfill.enumerated_at.present?,
      pending: @counts.fetch('pending', 0), errors: @counts.fetch('error', 0),
      error_codes: @monitor.evaluations.where(status: 'error').distinct.pluck(:error_code).compact,
      resume_mode: @resumption&.mode,
      has_gaps: @has_gaps,
      coverage_complete: coverage_complete?
    }
  end

  def historical_completed
    @monitor.evaluations.where(conversation_id: @backfill.population.select(:id), status: %w[matched unmatched]).count
  end

  def coverage_complete?
    @backfill.enumerated_at.present? && @historical_completed == @historical_eligible &&
      @counts.values_at('pending', 'error', 'skipped').compact.sum.zero? && !catching_up? && !@has_gaps
  end

  def state
    return 'archived' if @monitor.archived_at
    return 'paused' if @monitor.paused_at

    collection_state
  end

  def collection_state
    return 'needs_attention' unless ConversationMonitors::Configuration.configured?
    return 'rechecking' if @monitor.recheck_requested_at
    return 'catching_up' if catching_up?
    return 'scanning' if initial_scan_pending?
    return 'needs_attention' if @counts.fetch('error', 0).positive?
    return 'processing' if @counts.fetch('pending', 0).positive?

    live_state
  end

  def live_state
    work = ConversationMonitors::WorkItem.where(account_id: @monitor.account_id).where.not(due_at: nil)
    work = work.where(activity_at: @monitor.resumed_at..) if @monitor.resumed_at
    pending = work.minimum(:requested_at)
    return 'live' unless pending

    pending < 2.minutes.ago ? 'delayed' : 'processing'
  end

  def catching_up?
    @resumption&.mode == 'catch_up' && !@resumption.enumerated_at && !@resumption.cancelled_at
  end

  def initial_scan_pending?
    !@monitor.resumed_at && (!@backfill.enumerated_at || @historical_completed < @historical_eligible)
  end
end
