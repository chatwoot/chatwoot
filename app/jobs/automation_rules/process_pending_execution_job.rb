class AutomationRules::ProcessPendingExecutionJob < ApplicationJob
  queue_as :medium

  discard_on ActiveRecord::RecordNotFound

  def perform(pending_execution)
    # The sweep also checks this, but rows already enqueued when the switch flips must not
    # keep firing; they return to pending and replay or expire via the due window.
    return pending_execution.update!(status: :pending) if delayed_automations_disabled?

    skip_reason = skip_reason_for(pending_execution)
    return pending_execution.update!(status: :skipped, skip_reason: skip_reason) if skip_reason

    execute(pending_execution)
  rescue StandardError => e
    # Row stays `processing`; the sweep's stale reclaim retries it later.
    ChatwootExceptionTracker.new(e, account: pending_execution.account).capture_exception
  end

  private

  def skip_reason_for(pending_execution)
    rule = pending_execution.automation_rule
    return 'rule_inactive' if rule.nil? || !rule.active?
    return 'flag_disabled' unless pending_execution.account.feature_enabled?('delayed_automations')
    return 'conversation_gone' if pending_execution.conversation.nil?
    return 'episode_moved' unless pending_execution.episode_current?
    return 'conditions_changed' unless conditions_still_match?(pending_execution)

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
