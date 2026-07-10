class AutomationRules::TriggerPendingExecutionsJob < ApplicationJob
  queue_as :scheduled_jobs

  DEFAULT_SWEEP_LIMIT = 1000

  def perform
    return if delayed_automations_disabled?

    started_at = Time.current
    reclaimed = AutomationRulePendingExecution.reclaim_stale!
    expired = AutomationRulePendingExecution.expire_overdue!
    due_count = AutomationRulePendingExecution.due.count

    enqueued = 0
    AutomationRulePendingExecution.due.limit(sweep_limit).find_each(batch_size: 100) do |pending_execution|
      next unless pending_execution.mark_processing!

      AutomationRules::ProcessPendingExecutionJob.perform_later(pending_execution)
      enqueued += 1
    end

    log_summary(due: due_count, enqueued: enqueued, expired: expired, reclaimed: reclaimed, started_at: started_at)
  end

  private

  def delayed_automations_disabled?
    GlobalConfig.get('DISABLE_DELAYED_AUTOMATIONS')['DISABLE_DELAYED_AUTOMATIONS']
  end

  def sweep_limit
    (InstallationConfig.find_by(name: 'AUTOMATION_PENDING_EXECUTIONS_SWEEP_LIMIT')&.value || DEFAULT_SWEEP_LIMIT).to_i
  end

  def log_summary(due:, enqueued:, expired:, reclaimed:, started_at:)
    summary = {
      event: 'completed', due: due, enqueued: enqueued, capped: due > enqueued,
      expired: expired, reclaimed: reclaimed, duration_ms: ((Time.current - started_at) * 1000).round
    }
    Rails.logger.info("[AutomationRules::TriggerPendingExecutionsJob] #{summary.to_json}")
  end
end
