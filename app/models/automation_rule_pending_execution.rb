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
  # A processing row whose lock is older than this is treated as abandoned and reclaimed.
  STALE_PROCESSING_TIMEOUT = 15.minutes
  # Terminal rows are purged after this to keep the table bounded.
  RETENTION_WINDOW = 30.days

  belongs_to :automation_rule
  belongs_to :conversation
  belongs_to :account
  belongs_to :message, optional: true

  enum status: { pending: 0, processing: 1, executed: 2, skipped: 3 }

  # Rows a sweep should hand to a worker: due pending rows, plus processing rows whose lock went stale.
  scope :sweepable, lambda {
    pending.where(due_at: ..Time.current).or(processing.where(updated_at: ...STALE_PROCESSING_TIMEOUT.ago))
  }

  def self.schedule(rule:, conversation:, message: nil)
    key = arm_episode_key_for(conversation, message)
    create!(
      automation_rule: rule, conversation: conversation, account_id: conversation.account_id,
      message_id: message&.id, episode_key: key, due_at: rule.execution_delay.minutes.from_now
    )
  rescue ActiveRecord::RecordNotUnique
    # Episode already armed. Reply-chase tracks the latest agent reply, so its clock moves;
    # status / awaiting-agent episodes keep the first clock. A terminal row is never re-armed.
    return unless message && !message.incoming?

    row = find_by!(automation_rule_id: rule.id, conversation_id: conversation.id, episode_key: key)
    row.update!(due_at: rule.execution_delay.minutes.from_now, message_id: message.id) if row.pending?
  end

  # waiting_since is written just after MESSAGE_CREATED dispatches, so it can still be nil when
  # an awaiting-agent episode arms. It becomes the starting message's created_at, so use that
  # here; the strict fire-time key (episode_key_for) then matches once waiting_since is settled.
  def self.arm_episode_key_for(conversation, message)
    return episode_key_for(conversation, message) unless message&.incoming? && conversation.waiting_since.blank?

    "awaiting_agent:#{message.created_at.to_i}"
  end

  # Episode keys identify one qualifying stretch of conversation state; when the recomputed
  # key no longer matches, the episode ended and the pending action is cancelled at fire time.
  def self.episode_key_for(conversation, message)
    if message.nil?
      # Sub-second precision so a resolve→reopen inside one second still ends the episode.
      "status:#{(conversation.status_changed_at.presence || conversation.created_at).to_f}"
    elsif message.incoming?
      # waiting_since is cleared on agent/bot reply, so a reply invalidates this episode.
      # Strict here: at fire time a nil waiting_since means the agent replied (episode ended).
      "awaiting_agent:#{conversation.waiting_since.to_i}"
    else
      # A new customer message changes the max incoming id, invalidating this episode.
      "reply_chase:#{conversation.messages.incoming.maximum(:id) || 0}"
    end
  end

  def self.purge_terminal!
    where(status: [statuses[:executed], statuses[:skipped]], updated_at: ...RETENTION_WINDOW.ago)
      .in_batches(of: 1000).delete_all
  end

  # Atomic claim: only one worker can move a row into processing, so a row re-enqueued by an
  # overlapping sweep (or after a stale reclaim) cannot double-execute. Refreshing updated_at
  # renews the lock, keeping the row out of the stale window while this worker holds it.
  def claim!
    with_lock do
      next false unless claimable?

      update!(status: :processing, updated_at: Time.current)
      true
    end
  end

  def episode_current?
    self.class.episode_key_for(conversation, message) == episode_key
  end

  private

  def claimable?
    pending? || (processing? && updated_at < STALE_PROCESSING_TIMEOUT.ago)
  end
end
