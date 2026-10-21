# == Schema Information
#
# Table name: copilot_runs
#
#  id                   :bigint           not null, primary key
#  attempts             :integer          default(0), not null
#  context              :jsonb            not null
#  cost_complete        :boolean          default(TRUE), not null
#  error                :string
#  lease_token          :string
#  lease_until          :datetime
#  status               :string           default("queued"), not null
#  total_cost_usd       :decimal(16, 10)  default(0.0), not null
#  transcript           :jsonb            not null
#  type                 :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  account_id           :bigint           not null
#  copilot_message_id   :bigint
#  copilot_thread_id    :bigint           not null
#  copilot_tool_call_id :bigint
#  source_run_id        :bigint
#  user_id              :bigint           not null
#
# Indexes
#
#  index_copilot_runs_on_account_id            (account_id)
#  index_copilot_runs_on_copilot_message_id    (copilot_message_id) UNIQUE
#  index_copilot_runs_on_copilot_thread_id     (copilot_thread_id)
#  index_copilot_runs_on_copilot_tool_call_id  (copilot_tool_call_id) UNIQUE
#  index_copilot_runs_on_source_run_id         (source_run_id)
#  index_copilot_runs_on_user_id               (user_id)
#
# One proposed change and the records it targets. It waits on an approval card and writes nothing until the agent
# approves it. ActionJob then applies it in batches.
class CopilotRun::Action < CopilotRun
  include Concerns::CopilotRunProgress

  STATUSES = %w[awaiting_approval queued running completed incomplete rejected expired].freeze
  # The approval card shows a fixed set of conversations. After this long that set may be stale, so the agent has to ask again.
  APPROVAL_TTL = 5.minutes

  has_many :action_items, class_name: 'CopilotActionItem', dependent: :delete_all, inverse_of: :copilot_run

  validates :status, inclusion: { in: STATUSES }
  validates :target_ids, presence: true
  validate :action_name_present

  def action
    Captain::Copilot::Actions.build(context.fetch('action'), account: account, user: user, arguments: context.fetch('arguments'))
  end

  def target_ids
    context.fetch('target_ids', [])
  end

  def remaining_ids
    target_ids - action_items.finished.pluck(:record_id)
  end

  def summary
    counts = action_items.group(:status).count
    super.merge({ action: context['action'], arguments: context['arguments'], targets: target_ids.size, applied: counts['applied'].to_i,
                  skipped: counts['skipped'].to_i, failed: counts['failed'].to_i, not_processed: not_processed(counts),
                  decision_reason: context['decision_reason'] }.compact)
  end

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

  # A new message replaces the change. The turn that proposed it ends without another answer, so the agent's new message
  # is answered next and in order. The turn stays incomplete, so later turns read it as an outline.
  def supersede
    return false unless decide(:rejected, reason: I18n.t('captain.copilot.approval_superseded'))

    turn = copilot_tool_call.copilot_run
    turn.with_lock do
      copilot_tool_call.update!(status: :completed, result: summary)
      turn.release!(:incomplete) if turn.awaiting_background_run?
    end
    true
  end

  def expire
    close(:expired, I18n.t('captain.copilot.approval_expired', minutes: APPROVAL_TTL.in_minutes.to_i))
  end

  # The approval card's status: awaiting_approval until the agent decides, then approved, rejected or expired.
  def approval_status
    awaiting_approval? || rejected? || expired? ? status : 'approved'
  end

  def approval_expired?
    created_at <= APPROVAL_TTL.ago
  end

  def approval_card
    copilot_thread.copilot_messages.find(context.fetch('approval_message_id'))
  end

  private

  def action_name_present
    errors.add(:action, :blank) if context['action'].blank?
  end

  def progress_text(progress)
    "Applied #{progress[:applied]} of #{progress[:targets]} changes: #{progress[:skipped]} already done, #{progress[:failed]} failed."
  end

  # Targets an approved change never reached, such as when workflows were turned off partway through.
  def not_processed(counts)
    return unless completed? || incomplete?

    missing = target_ids.size - counts.values_at(*CopilotActionItem::FINISHED_STATUSES).sum(&:to_i)
    missing if missing.positive?
  end

  # Closing hands the decision back to the waiting tool call, so the turn continues without the change.
  def close(new_status, reason)
    decided = decide(new_status, reason: reason)
    copilot_tool_call.copilot_run.resume_with(copilot_tool_call, summary) if decided
    decided
  end

  def decide(new_status, reason: nil)
    with_lock do
      next false unless awaiting_approval?

      update!(status: new_status, context: context.merge('decision_reason' => reason).compact)
      card = approval_card
      card.update!(message: card.message.deep_merge('approval' => { 'status' => approval_status }))
    end
  end
end
