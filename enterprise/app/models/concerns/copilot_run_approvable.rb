# An action run waits on an approval card and writes nothing until the agent approves it.
module Concerns::CopilotRunApprovable
  extend ActiveSupport::Concern

  # The approval card shows a fixed set of conversations. After this long that set may be stale, so the agent has to ask again.
  APPROVAL_TTL = 5.minutes

  # Approving starts the action. Returns false when the action was already decided, or has expired, which also closes it.
  def approve
    if approval_expired?
      expire
      return false
    end

    decided = decide(:queued)
    Captain::Copilot::ActionJob.perform_later(id) if decided
    decided
  end

  def reject(reason)
    close(:rejected, reason)
  end

  def expire
    close(:expired, I18n.t('captain.copilot.approval_expired', minutes: APPROVAL_TTL.in_minutes.to_i))
  end

  # The approval card's status: awaiting_approval until the agent decides, then approved, rejected or expired.
  def approval_status
    awaiting_approval? || rejected? || expired? ? status : 'approved'
  end

  def approval_expired?
    Time.iso8601(context.fetch('approval_expires_at')).past?
  end

  private

  # Closing hands the decision back to the waiting tool call, so the turn continues without the change.
  def close(new_status, reason)
    decided = decide(new_status, reason: reason)
    copilot_tool_call.copilot_run.resume_with(copilot_tool_call, summary) if decided
    decided
  end

  def decide(new_status, reason: nil)
    with_lock do
      next false unless awaiting_approval?

      update!(status: new_status, context: context.merge('decided_at' => Time.current.iso8601, 'decision_reason' => reason).compact)
      card = copilot_thread.copilot_messages.find(context.fetch('approval_message_id'))
      card.update!(message: card.message.deep_merge('approval' => { 'status' => approval_status }))
    end
  end
end
