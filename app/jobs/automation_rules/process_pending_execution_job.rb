class AutomationRules::ProcessPendingExecutionJob < ApplicationJob
  queue_as :medium

  discard_on ActiveJob::DeserializationError

  def perform(pending_execution)
    return if delayed_automations_disabled?
    # Account flag off pauses (not skips): leave the row pending so re-enabling resumes it.
    return unless pending_execution.account.feature_enabled?('delayed_automations')
    # Atomic claim: a duplicate enqueue (overlapping sweep or stale reclaim) loses here and returns.
    return unless pending_execution.claim!

    skip_reason = skip_reason_for(pending_execution)
    return pending_execution.update!(status: :skipped, skip_reason: skip_reason) if skip_reason

    execute(pending_execution)
  rescue StandardError => e
    # Row stays `processing`; the next sweep reclaims and retries it once the lock goes stale.
    ChatwootExceptionTracker.new(e, account: pending_execution.account).capture_exception
  end

  private

  def skip_reason_for(pending_execution)
    return 'expired' if pending_execution.due_at < AutomationRulePendingExecution::DUE_WINDOW.ago

    structural_skip_reason(pending_execution) || behavioral_skip_reason(pending_execution)
  end

  def structural_skip_reason(pending_execution)
    rule = pending_execution.automation_rule
    return 'rule_inactive' if rule.nil? || !rule.active?
    return 'conversation_gone' if pending_execution.conversation.nil?

    nil
  end

  def behavioral_skip_reason(pending_execution)
    return 'episode_moved' unless pending_execution.episode_current?
    return AutomationRulePendingExecution::CONDITIONS_CHANGED_SKIP unless conditions_still_match?(pending_execution)

    nil
  end

  def conditions_still_match?(pending_execution)
    AutomationRules::ConditionsFilterService.new(
      pending_execution.automation_rule,
      pending_execution.conversation,
      { message: pending_execution.message }
    ).perform.present?
  end

  def execute(pending_execution)
    AutomationRules::ActionService.new(
      pending_execution.automation_rule,
      pending_execution.account,
      pending_execution.conversation
    ).perform
    pending_execution.update!(status: :executed)
  end

  def delayed_automations_disabled?
    GlobalConfig.get('DISABLE_DELAYED_AUTOMATIONS')['DISABLE_DELAYED_AUTOMATIONS']
  end
end
