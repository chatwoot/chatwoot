class AutomationRules::ProcessPendingExecutionJob < ApplicationJob
  queue_as :medium

  discard_on ActiveJob::DeserializationError

  def perform(pending_execution)
    # Account flag off pauses (not skips): leave the row pending so re-enabling resumes it.
    return unless pending_execution.account.feature_enabled?('delayed_automations')
    # Atomic claim: a duplicate enqueue (overlapping sweep or stale reclaim) loses here and returns.
    return unless pending_execution.claim!
    # An inactivity wait is measured from the conversation's last activity, and some activity never
    # reaches a listener to re-arm the row. Push the clock instead of firing on a conversation that moved.
    return if reschedule_inactivity(pending_execution)

    skip_reason = skip_reason_for(pending_execution)
    return settle_skip(pending_execution, skip_reason) if skip_reason

    execute(pending_execution)
  rescue StandardError => e
    # Row stays `processing`; the next sweep reclaims and retries it once the lock goes stale.
    ChatwootExceptionTracker.new(e, account: pending_execution.account).capture_exception
  end

  private

  def reschedule_inactivity(pending_execution)
    due_at = pending_execution.inactivity_due_at
    return false if due_at.nil?

    if due_at.future?
      pending_execution.update!(status: :pending, due_at: due_at)
      return true
    end

    # The clock moved by less than it took to get here -- an arm anchored on a message, and the
    # write that message makes to the conversation landing a moment later, is enough -- so the wait
    # is already over and this worker is the one holding the row. Record where the count really
    # ended and carry on; handing the row back would cost a whole sweep to reach the same answer.
    pending_execution.update!(due_at: due_at)
    false
  end

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
    return unless start_run(pending_execution)

    # Read after the run started, never before: start_run may have recorded a deadline that had
    # already elapsed, and that activity is the one this run consumes. Kept from before, it would
    # read as new when the run settles and the actions would happen a second time.
    armed_for = pending_execution.due_at
    # Read before the actions, never after: a note, a reopen and an unassign are all messages, and a
    # message writes last_activity_at. Read afterwards, the run would see itself as the activity that
    # restarts the count, and an inbox-only rule would act again every delay for ever. Activity that
    # lands while the actions run is not lost by reading early -- it reaches the row as activity_seen_at.
    conversation_anchor = AutomationRulePendingExecution.activity_anchor_for(pending_execution.conversation, nil)
    AutomationRules::ActionService.new(
      pending_execution.automation_rule,
      pending_execution.account,
      pending_execution.conversation
    ).perform
    settle(pending_execution, armed_for, conversation_anchor)
  end

  # Marked `executing` before the actions run: a row that dies from here on stays there, which no
  # sweep reclaims, so a message/email/webhook is never sent twice. Everything up to this point is
  # still retryable.
  #
  # It is also the last look at the clock before anything customer-facing happens, taken under the
  # same lock the arm takes. Activity that landed while this worker was deciding moved the clock and left the
  # claimed row alone, deliberately, because a live worker keeps its row -- and everything since the
  # claim has been a decision, not an action, so it is still free to be abandoned. After the actions
  # there is nothing to undo, which is why this is the last place that reading can happen.
  def start_run(pending_execution)
    pending_execution.with_lock do
      due_at = pending_execution.inactivity_due_at
      if due_at&.future?
        pending_execution.update!(status: :pending, due_at: due_at)
        next false
      end

      # Nothing moved, or it moved by less than the wait had left: either way the count is over and
      # the row is this worker's. The deadline still records where it really ended.
      pending_execution.due_at = due_at if due_at
      pending_execution.update!(status: :executing)
      true
    end
  end

  # A skip is as terminal as a run, and terminal rows are never swept again, so activity that landed
  # while this worker was deciding would be buried with the skip. An inactivity row goes terminal
  # only with nothing left on its clock, whichever way the decision went.
  def settle_skip(pending_execution, skip_reason)
    pending_execution.with_lock do
      due_at = pending_execution.inactivity_due_at
      next pending_execution.update!(status: :pending, skip_reason: nil, due_at: due_at) if due_at

      pending_execution.update!(status: :skipped, skip_reason: skip_reason)
    end
  end

  # Activity that landed while this worker held the row moved the clock and not the status. Reading
  # it here is what starts the next count from that activity instead of dropping it: an executed
  # row is never swept again. Somebody else's activity, that is: the conversation's own clock is
  # the snapshot taken before the actions ran, so what this run wrote is not read back as movement.
  def settle(pending_execution, armed_for, conversation_anchor)
    pending_execution.with_lock do
      due_at = pending_execution.inactivity_due_at(armed_for: armed_for, conversation_anchor: conversation_anchor)
      next pending_execution.update!(status: :pending, due_at: due_at) if due_at

      pending_execution.update!(status: :executed)
    end
  end
end
