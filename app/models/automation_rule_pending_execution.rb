# == Schema Information
#
# Table name: automation_rule_pending_executions
#
#  id                 :bigint           not null, primary key
#  due_at             :datetime         not null
#  episode_key        :string           not null
#  skip_reason        :string
#  status             :integer          default("pending"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#  automation_rule_id :bigint           not null
#  conversation_id    :bigint           not null
#  message_id         :bigint
#
# Indexes
#
#  index_automation_rule_pending_executions_on_account_id          (account_id)
#  index_automation_rule_pending_executions_on_automation_rule_id  (automation_rule_id)
#  index_automation_rule_pending_executions_on_conversation_id     (conversation_id)
#  index_automation_rule_pending_executions_on_status_and_due_at   (status,due_at)
#  uniq_automation_pending_execution_episode                       (automation_rule_id,conversation_id,episode_key) UNIQUE
#
class AutomationRulePendingExecution < ApplicationRecord
  # Rows older than this never fire (bounds backlog replay after downtime).
  DUE_WINDOW = 3.days
  # Claimed rows abandoned by a crashed worker return to the sweep after this.
  STALE_PROCESSING_TIMEOUT = 15.minutes

  belongs_to :automation_rule
  belongs_to :conversation
  belongs_to :account
  belongs_to :message, optional: true

  enum status: { pending: 0, processing: 1, executed: 2, skipped: 3 }

  scope :due, -> { pending.where(due_at: DUE_WINDOW.ago..Time.current) }

  def self.schedule(rule:, conversation:, message: nil)
    attributes = {
      automation_rule_id: rule.id,
      conversation_id: conversation.id,
      account_id: conversation.account_id,
      message_id: message&.id,
      episode_key: episode_key_for(conversation, message),
      due_at: rule.execution_delay.minutes.from_now,
      created_at: Time.current,
      updated_at: Time.current
    }

    # Values are server-computed and the unique episode index is the real guard, so the
    # validation-skipping conflict-handling writes are safe here (repo bulk-write convention).
    # rubocop:disable Rails/SkipsModelValidations
    if message && !message.incoming?
      # Reply-chase: the clock tracks the latest agent reply. Status is excluded from the
      # update list so an executed/skipped episode is never re-armed (run-once per episode).
      upsert(attributes, unique_by: :uniq_automation_pending_execution_episode,
                         on_duplicate: Arel.sql('due_at = excluded.due_at, message_id = excluded.message_id, updated_at = excluded.updated_at'))
    else
      # Status / awaiting-agent episodes: first event wins, the clock is not reset.
      insert(attributes, unique_by: :uniq_automation_pending_execution_episode)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end

  # Episode keys identify one qualifying stretch of conversation state; when the recomputed
  # key no longer matches, the episode ended and the pending action is cancelled at fire time.
  def self.episode_key_for(conversation, message)
    if message.nil?
      # Sub-second precision so a resolve→reopen inside one second still ends the episode.
      "status:#{(conversation.status_changed_at.presence || conversation.created_at).to_f}"
    elsif message.incoming?
      # waiting_since is cleared on agent/bot reply, so a reply invalidates this episode.
      "awaiting_agent:#{conversation.waiting_since.to_i}"
    else
      # A new customer message changes the max incoming id, invalidating this episode.
      "reply_chase:#{conversation.messages.incoming.maximum(:id) || 0}"
    end
  end

  # Bulk state flips on exceptional sets; batched so no statement outlives the global 14s
  # statement_timeout (repo bulk-write convention, see Agents::DestroyJob).
  # rubocop:disable Rails/SkipsModelValidations
  def self.expire_overdue!
    expired_count = 0
    pending.where(due_at: ...DUE_WINDOW.ago).in_batches(of: 1000) do |batch|
      expired_count += batch.update_all(status: statuses[:skipped], skip_reason: 'expired', updated_at: Time.current)
    end
    expired_count
  end

  def self.reclaim_stale!
    reclaimed_count = 0
    processing.where(updated_at: ...STALE_PROCESSING_TIMEOUT.ago).in_batches(of: 1000) do |batch|
      reclaimed_count += batch.update_all(status: statuses[:pending], updated_at: Time.current)
    end
    reclaimed_count
  end
  # rubocop:enable Rails/SkipsModelValidations

  # Locked claim so a row re-selected by an overlapping sweep can't double-fire
  # (Campaign#mark_processing! pattern).
  def mark_processing!
    with_lock do
      next false unless pending?

      processing!
      true
    end
  end

  def episode_current?
    self.class.episode_key_for(conversation, message) == episode_key
  end
end
