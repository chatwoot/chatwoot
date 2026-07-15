class AutomationRules::ResumePausedExecutionsJob < ApplicationJob
  # Enqueued the moment the account flag flips back on, ahead of the next sweep, so overdue rows
  # are rescheduled before that sweep's per-row jobs could mark them expired.
  queue_as :medium

  discard_on ActiveJob::DeserializationError

  def perform(account)
    AutomationRulePendingExecution.reschedule_paused(account)
  end
end
