class ConversationMonitors::Presenter
  SCAN_STATES = { 'initial' => 'scanning', 'catch_up' => 'catching_up' }.freeze

  def initialize(monitor)
    @monitor = monitor
  end

  def as_json
    {
      id: @monitor.id, name: @monitor.name, condition: @monitor.condition,
      created_at: @monitor.created_at.to_i, history_since: @monitor.history_since.to_i,
      data_revision: @monitor.data_revision, collection_version: @monitor.collection_version,
      # Report bounds are whole seconds; include matches created within the pause second.
      paused_at: @monitor.paused_at&.ceil&.to_i,
      recent_count: @monitor.matched_conversations.where(created_at: ((@monitor.paused_at || Time.current) - 7.days)..).count,
      processing: processing
    }
  end

  private

  def processing
    @counts = @monitor.evaluations.group(:status).count
    {
      state: state, errors: @counts.fetch('error', 0),
      error_codes: @monitor.evaluations.where(status: 'error').distinct.pluck(:error_code).compact
    }
  end

  def state
    return 'paused' if @monitor.paused_at
    return 'needs_attention' unless ConversationMonitors::Configuration.configured?
    return 'rechecking' if @monitor.recheck_requested_at

    scan = @monitor.scans.pending.find_by(collection_version: @monitor.collection_version)
    return SCAN_STATES.fetch(scan.kind) if scan
    return 'needs_attention' if @counts.fetch('error', 0).positive?
    return 'processing' if @counts.fetch('pending', 0).positive?

    live_state
  end

  def live_state
    work = ConversationMonitors::WorkItem.where(account_id: @monitor.account_id).where.not(due_at: nil)
    work = work.where(activity_at: (@monitor.resumed_at || @monitor.created_at)..)
    pending = work.minimum(:requested_at)
    return 'live' unless pending

    pending < 2.minutes.ago ? 'delayed' : 'processing'
  end
end
