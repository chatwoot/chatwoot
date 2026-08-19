class AutomationRules::TriggerPendingExecutionsJob < ApplicationJob
  queue_as :scheduled_jobs

  DEFAULT_SWEEP_LIMIT = 1000

  def perform
    started_at = Time.current
    purged = AutomationRulePendingExecution.purge_terminal!

    rows = AutomationRulePendingExecution.sweepable.for_enabled_accounts.order(:due_at).limit(sweep_limit).to_a
    rows.each { |row| AutomationRules::ProcessPendingExecutionJob.perform_later(row) }

    log_summary(enqueued: rows.size, capped: rows.size >= sweep_limit, purged: purged,
                abandoned: AutomationRulePendingExecution.abandoned.count, started_at: started_at)
  end

  private

  def sweep_limit
    (InstallationConfig.find_by(name: 'AUTOMATION_PENDING_EXECUTIONS_SWEEP_LIMIT')&.value || DEFAULT_SWEEP_LIMIT).to_i
  end

  def log_summary(enqueued:, capped:, purged:, abandoned:, started_at:)
    summary = { event: 'completed', enqueued: enqueued, capped: capped, purged: purged, abandoned: abandoned,
                duration_ms: ((Time.current - started_at) * 1000).round }
    Rails.logger.info("[AutomationRules::TriggerPendingExecutionsJob] #{summary.to_json}")
  end
end
