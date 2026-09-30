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

        evaluation = monitor.evaluations.find_or_initialize_by(conversation_id: @work.conversation_id, account_id: @work.account_id)
        return if evaluation.status == 'matched' || evaluation.input_revision > @snapshot[:revision]

        evaluation.update!(attributes(monitor, score, model, error))
        monitor.update!(data_revision: monitor.data_revision + 1)
      end
    end
  rescue ActiveRecord::RecordNotFound, ActiveRecord::InvalidForeignKey
    # The source or monitor was deleted while the provider call was running.
    nil
  end

  private

  def current?
    @work.lease_token == @snapshot[:token] && @work.generation == @snapshot[:generation]
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
end
