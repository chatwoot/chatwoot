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
  # Skip reason for a row cancelled only because conditions no longer matched at fire time; unlike
  # other terminal reasons, a later qualifying message can re-arm it (see .schedule).
  CONDITIONS_CHANGED_SKIP = 'conditions_changed'.freeze

  belongs_to :automation_rule
  belongs_to :conversation
  belongs_to :account
  belongs_to :message, optional: true

  enum status: { pending: 0, processing: 1, executed: 2, skipped: 3 }

  # Rows a sweep should hand to a worker: due pending rows, plus processing rows whose lock went stale.
  scope :sweepable, lambda {
    pending.where(due_at: ..Time.current).or(processing.where(updated_at: ...STALE_PROCESSING_TIMEOUT.ago))
  }

  # Non-terminal rows still bound to fire (a stale processing row is reclaimed by the sweep).
  scope :armed, -> { where(status: [statuses[:pending], statuses[:processing]]) }

  # Excludes rows whose account paused delayed automations, so one disabled account's backlog
  # can't fill the sweep limit and starve enabled accounts (paused rows resume on re-enable).
  scope :for_enabled_accounts, -> { joins(:account).merge(Account.feature_delayed_automations) }

  def self.schedule(rule:, conversation:, message: nil)
    key = arm_episode_key_for(conversation, message)
    anchor = arm_anchor_for(conversation, message)
    create!(
      automation_rule: rule, conversation: conversation, account_id: conversation.account_id,
      message_id: message&.id, episode_key: key, due_at: rule.execution_delay.minutes.since(anchor)
    )
  rescue ActiveRecord::RecordNotUnique
    rearm_or_advance_episode(rule, conversation, key, message, anchor)
  end

  # The episode is already armed. Status episodes keep their first clock (a status change would
  # give a new key), so only message episodes advance or re-arm here.
  def self.rearm_or_advance_episode(rule, conversation, key, message, anchor)
    return unless message

    row = find_by!(automation_rule_id: rule.id, conversation_id: conversation.id, episode_key: key)
    # Jobs can arrive out of order; only a strictly newer message advances or re-arms, so a late
    # older message can't pull due_at backwards and fire before the delay elapses.
    return unless message.id > row.message_id

    due_at = rule.execution_delay.minutes.since(anchor)
    if row.condition_skipped?
      # A message episode key can recur (no new incoming reply) while conditions swing back into
      # match, so a later qualifying message re-arms the condition-only skip instead of dropping.
      row.update!(status: :pending, skip_reason: nil, due_at: due_at, message_id: message.id)
    elsif !row.terminal?
      # Track the newest qualifying message. Reply-chase advances due_at with each agent reply;
      # awaiting-agent keeps its first clock (its anchor is the stable waiting_since, so due_at is
      # unchanged). Re-anchoring a row still processing (its worker died mid-run) back to pending
      # also keeps a stale reclaim from firing the old clock instead of the latest one.
      row.update!(status: :pending, due_at: due_at, message_id: message.id)
    end
  end

  # The wait is measured from when the qualifying event happened, not when this (possibly
  # backlogged or retried) listener runs, so a late dispatch still fires on schedule. Mirrors
  # the timestamps the episode keys track.
  def self.arm_anchor_for(conversation, message)
    if message.nil?
      conversation.status_changed_at.presence || conversation.created_at
    elsif message.incoming?
      conversation.waiting_since.presence || message.created_at
    else
      message.created_at
    end
  end

  # waiting_since is written just after MESSAGE_CREATED dispatches, so it can still be nil when
  # an awaiting-agent episode arms. It becomes the starting message's created_at, so use that
  # here; the strict fire-time key (episode_key_for) then matches once waiting_since is settled.
  def self.arm_episode_key_for(conversation, message)
    return episode_key_for(conversation, message) unless message&.incoming? && conversation.waiting_since.blank?

    "awaiting_agent:#{microsecond_stamp(message.created_at)}"
  end

  # Microsecond integer, not a float: epoch seconds carry ~16 significant digits, past float64's
  # precision, so an in-memory timestamp (arm time) and its DB-reloaded value (fire time) would
  # round to different floats. strftime is exact on both. Sub-second distinguishes rapid episodes.
  def self.microsecond_stamp(time)
    time&.strftime('%s%6N') || '0'
  end

  # Episode keys identify one qualifying stretch of conversation state; when the recomputed
  # key no longer matches, the episode ended and the pending action is cancelled at fire time.
  def self.episode_key_for(conversation, message)
    if message.nil?
      # Sub-second precision so a resolve→reopen inside one second still ends the episode.
      # Integer microseconds (not a float) so an in-memory arm and a DB-reloaded fire agree.
      "status:#{microsecond_stamp(conversation.status_changed_at.presence || conversation.created_at)}"
    elsif message.incoming?
      # waiting_since is cleared on agent/bot reply, so a reply invalidates this episode. Strict
      # here: at fire time a nil waiting_since means the agent replied (episode ended).
      "awaiting_agent:#{microsecond_stamp(conversation.waiting_since)}"
    else
      # A new customer message changes the max incoming id, invalidating this episode.
      "reply_chase:#{conversation.messages.incoming.maximum(:id) || 0}"
    end
  end

  def self.purge_terminal!
    where(status: [statuses[:executed], statuses[:skipped]], updated_at: ...RETENTION_WINDOW.ago)
      .in_batches(of: 1000).delete_all
  end

  # Rows that came due while an account had delayed automations paused would expire the moment
  # the sweep reaches them on resume. Reset their clock so pause/resume replays them (still
  # subject to the fire-time episode/condition re-checks) instead of silently dropping them.
  def self.reschedule_paused(account)
    overdue = pending.where(account_id: account.id, due_at: ...DUE_WINDOW.ago)
    overdue.find_each { |row| row.update!(due_at: Time.current) }
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

  def condition_skipped?
    skipped? && skip_reason == CONDITIONS_CHANGED_SKIP
  end

  def terminal?
    executed? || skipped?
  end

  private

  def claimable?
    # due_at guard: a reply-chase reschedule can push due_at forward after this row was enqueued;
    # such a row must wait for a later sweep instead of firing early.
    (pending? && due_at <= Time.current) || (processing? && updated_at < STALE_PROCESSING_TIMEOUT.ago)
  end
end
