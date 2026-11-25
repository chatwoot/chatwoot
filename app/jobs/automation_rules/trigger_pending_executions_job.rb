class AutomationRules::TriggerPendingExecutionsJob < ApplicationJob
  queue_as :scheduled_jobs

  DEFAULT_SWEEP_LIMIT = 1000

  def perform
    started_at = Time.current
    purged = AutomationRulePendingExecution.purge_terminal!
    recovered = AutomationRulePendingExecution.recover_abandoned_with_activity!(limit: sweep_limit)

    rows = AutomationRulePendingExecution.sweepable.for_enabled_accounts.order(:due_at).limit(sweep_limit).to_a
    rows.each { |row| AutomationRules::ProcessPendingExecutionJob.perform_later(row) }

    log_summary(started_at, enqueued: rows.size, capped: rows.size >= sweep_limit, purged: purged,
                            recovered: recovered, abandoned: AutomationRulePendingExecution.abandoned.count)
  end

  private

  def sweep_limit
    (InstallationConfig.find_by(name: 'AUTOMATION_PENDING_EXECUTIONS_SWEEP_LIMIT')&.value || DEFAULT_SWEEP_LIMIT).to_i
  end

  def log_summary(started_at, **counts)
    summary = { event: 'completed', **counts, duration_ms: ((Time.current - started_at) * 1000).round }
    Rails.logger.info("[AutomationRules::TriggerPendingExecutionsJob] #{summary.to_json}")
  end
end
