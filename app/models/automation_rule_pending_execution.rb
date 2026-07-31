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
#  index_automation_pending_executions_on_status_and_updated_at    (status,updated_at)
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

  # `processing` is claimed but not yet acting, so it is safe to reclaim and retry. `executing`
  # means the actions are running: a row that dies there is never replayed, because the actions
  # are customer-facing (messages, emails, webhooks) and repeating them is worse than dropping them.
  enum status: { pending: 0, processing: 1, executed: 2, skipped: 3, executing: 4 }

  # Processing rows whose worker died: the claim renews updated_at, so a lock past the timeout is abandoned.
  scope :stale_processing, -> { processing.where(updated_at: ...STALE_PROCESSING_TIMEOUT.ago) }

  # Rows a sweep should hand to a worker: due pending rows, plus processing rows whose lock went stale.
  scope :sweepable, -> { pending.where(due_at: ..Time.current).or(stale_processing) }

  # Rows whose worker died mid-action. Nothing reclaims them; the sweep only counts them so a
  # crash that strands customer-facing actions is visible instead of silent.
  scope :abandoned, -> { executing.where(updated_at: ...STALE_PROCESSING_TIMEOUT.ago) }

  # Non-terminal rows still bound to fire (a stale processing row is reclaimed by the sweep).
  scope :armed, -> { where(status: [statuses[:pending], statuses[:processing]]) }

  # Excludes rows whose account paused delayed automations, so one disabled account's backlog
  # can't fill the sweep limit and starve enabled accounts (paused rows resume on re-enable).
  scope :for_enabled_accounts, -> { joins(:account).merge(Account.feature_delayed_automations) }

  def self.schedule(rule:, conversation:, message: nil)
    # status_changed_at is only written from this feature onwards, so a conversation that predates it
    # has no status clock. Anchoring on created_at would make every old conversation instantly
    # overdue and fire on the next sweep; leave them for their next status change to arm.
    return if message.nil? && conversation.status_changed_at.blank?

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

    due_at = rule.execution_delay.minutes.since(anchor)
    row = find_by!(automation_rule_id: rule.id, conversation_id: conversation.id, episode_key: key)
    # The lock (and the reload it does) makes the compare-and-write atomic. Two listeners racing on
    # the same episode would otherwise both read the old message_id and let whichever wrote last
    # win, so an older message could overwrite a newer one and pull due_at backwards.
    row.with_lock do
      # Jobs can arrive out of order; only a strictly newer message advances or re-arms, so a late
      # older message can't pull due_at backwards and fire before the delay elapses.
      next unless message.id > row.message_id
      # A row that already acted keeps its episode's single run, and a live worker keeps its row.
      next unless row.pending? || row.skipped? || row.stale_processing?

      # Track the newest qualifying message. Reply-chase advances due_at with each agent reply;
      # awaiting-agent keeps its first clock (its anchor is the stable waiting_since, so due_at is
      # unchanged). Re-anchoring a row whose worker died mid-run back to pending also keeps a stale
      # reclaim from firing the old clock instead of the latest one. A skipped row re-arms whatever
      # the reason: its key recurs while the customer stays quiet, so leaving it terminal would
      # suppress every later message in the episode until the row is purged.
      row.update!(status: :pending, skip_reason: nil, due_at: due_at, message_id: message.id)
    end
  end

  # The wait is measured from when the qualifying event happened, not when this (possibly
  # backlogged or retried) listener runs, so a late dispatch still fires on schedule. Mirrors
  # the timestamps the episode keys track.
  def self.arm_anchor_for(conversation, message)
    if message.nil?
      conversation.status_changed_at
    elsif message.incoming?
      conversation.waiting_since.presence || message.created_at
    else
      message.created_at
    end
  end

  # Arming keys differ from the strict fire-time keys wherever current state can already reflect the
  # event the row waits for: MESSAGE_CREATED dispatches asynchronously, so this can run long after
  # the message it arms.
  def self.arm_episode_key_for(conversation, message)
    return episode_key_for(conversation, message) if message.nil?

    if message.incoming?
      # waiting_since is written just after MESSAGE_CREATED dispatches, so it can still be nil here.
      # It becomes the starting message's created_at, so use that; the strict fire-time key then
      # matches once waiting_since is settled.
      return episode_key_for(conversation, message) if conversation.waiting_since.present?

      "awaiting_agent:#{microsecond_stamp(message.created_at)}"
    else
      # Count only the replies that predate the agent message being chased. A customer reply that
      # landed while this job queued must end the episode at fire time, not be baked into its key.
      "reply_chase:#{conversation.messages.incoming.where(id: ...message.id).maximum(:id) || 0}"
    end
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
      "status:#{microsecond_stamp(conversation.status_changed_at)}"
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
  # Stale processing rows go back to pending too (their worker is gone); resetting due_at alone would
  # renew the lock and hold them out of the sweep for another timeout. A live worker keeps its row.
  def self.reschedule_paused(account)
    overdue = pending.or(stale_processing).where(account_id: account.id, due_at: ...DUE_WINDOW.ago)
    overdue.find_each { |row| row.update!(status: :pending, due_at: Time.current) }
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

  # The claim renews updated_at, so a processing row past the timeout means its worker died. Only
  # then may a re-arm take the row back: pulling a live worker's row to pending would let the sweep
  # claim it and run the same actions alongside the worker still executing them.
  def stale_processing?
    processing? && updated_at < STALE_PROCESSING_TIMEOUT.ago
  end

  def terminal?
    executed? || skipped?
  end

  private

  def claimable?
    # due_at guard: a reply-chase reschedule can push due_at forward after this row was enqueued;
    # such a row must wait for a later sweep instead of firing early.
    (pending? && due_at <= Time.current) || stale_processing?
  end
end
