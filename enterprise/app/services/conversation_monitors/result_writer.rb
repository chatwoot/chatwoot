class ConversationMonitors::ResultWriter
  def initialize(work, snapshot)
    @work = work
    @snapshot = snapshot
  end

  def write(monitor, score: nil, model: nil, error: nil)
    @work.with_lock do
      return unless current?

      monitor.with_lock do
        return unless monitor.collecting?
        return unless monitor.collection_version == @snapshot[:monitor_versions].fetch(monitor.id)

        record_result(monitor, score, model, error)
      end
    end
  rescue ActiveRecord::RecordNotFound, ActiveRecord::InvalidForeignKey
    # The source or monitor was deleted while the provider call was running.
    nil
  end

  private

  def record_result(monitor, score, model, error)
    evaluation = monitor.evaluations.find_or_initialize_by(conversation_id: @work.conversation_id, account_id: @work.account_id)
    return if evaluation.status == 'matched' || evaluation.input_revision > @snapshot[:revision]

    result = attributes(monitor, score, model, error)
    first_match = result[:status] == 'matched' && evaluation.first_matched_at.nil?
    result[:first_matched_at] = result[:matched_at] if first_match
    evaluation.update!(result)
    create_automation_deliveries(monitor) if first_match
    monitor.update!(data_revision: monitor.data_revision + 1)
  end

  def current?
    @work.lease_token == @snapshot[:token] && @work.generation == @snapshot[:generation] &&
      @work.revision == @snapshot[:revision]
  end

  def attributes(monitor, score, model, error)
    matched = error.nil? && score >= monitor.threshold
    {
      status: error ? 'error' : status_for(matched),
      score: score, model: model, error_code: error&.code,
      input_revision: @snapshot[:revision], generation: @snapshot[:generation],
      matched_at: matched ? Time.current : nil, evaluated_at: Time.current,
      requested_version: error ? monitor.collection_version : nil
    }
  end

  def status_for(matched)
    matched ? 'matched' : 'unmatched'
  end

  def create_automation_deliveries(monitor)
    activity_at = @snapshot[:live_activity_at]
    return unless activity_at && monitor.account.feature_enabled?('automations')

    monitor.automation_rules.active.where(event_name: 'monitor_matched')
           .where(monitor_event_activated_at: ..activity_at).find_each do |rule|
      create_automation_delivery(monitor, rule)
    end
  end

  def create_automation_delivery(monitor, rule)
    monitor.automation_deliveries.create!(account_id: monitor.account_id, conversation_id: @work.conversation_id,
                                          automation_rule: rule)
  end
end
