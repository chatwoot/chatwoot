# == Schema Information
#
# Table name: automation_rule_pending_executions
#
#  id                 :bigint           not null, primary key
#  activity_seen_at   :datetime
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
  # An inactivity wait has one episode per conversation: the count restarts on every activity
  # instead of ending, so the row is re-anchored in place rather than replaced by a new key.
  INACTIVITY_EPISODE_KEY = 'inactivity'.freeze

  belongs_to :automation_rule
  belongs_to :conversation
  belongs_to :account
  belongs_to :message, optional: true

  # `processing` is claimed but not yet acting, so it is safe to reclaim and retry. `executing`
  # means the actions are running: a row that dies there is never replayed, because the actions
  # are customer-facing (messages, emails, webhooks) and repeating them is worse than dropping them.
  enum :status, { pending: 0, processing: 1, executed: 2, skipped: 3, executing: 4 }

  # Processing rows whose worker died: the claim renews updated_at, so a lock past the timeout is abandoned.
  scope :stale_processing, -> { processing.where(updated_at: ...STALE_PROCESSING_TIMEOUT.ago) }

  # Rows a sweep should hand to a worker: due pending rows, plus processing rows whose lock went stale.
  scope :sweepable, -> { pending.where(due_at: ..Time.current).or(stale_processing) }

  # Rows whose worker died mid-action. Nothing reclaims them; the sweep only counts them so a
  # crash that strands customer-facing actions is visible instead of silent.
  scope :abandoned, -> { executing.where(updated_at: ...STALE_PROCESSING_TIMEOUT.ago) }

  # Non-terminal rows still bound to fire (a stale processing row is reclaimed by the sweep).
  scope :armed, -> { where(status: [statuses[:pending], statuses[:processing]]) }

  # Abandoned runs carrying activity their worker never read. Unconsumed is the SQL form of what the
  # row rechecks under its own lock: recorded later than the arm the row is running on. It is asked
  # here, and not row by row, because a rejected row is never removed from the table -- an abandoned
  # run stays abandoned -- so a batch filling up with rejects would starve the real ones for ever.
  scope :recoverable_abandoned, lambda {
    abandoned.joins(:automation_rule)
             .where(automation_rules: { execution_delay_trigger: 'inactivity' })
             .where('automation_rule_pending_executions.activity_seen_at > automation_rule_pending_executions.due_at ' \
                    "- (automation_rules.execution_delay * interval '1 minute')")
  }

  # Excludes rows whose account paused delayed automations, so one disabled account's backlog
  # can't fill the sweep limit and starve enabled accounts (paused rows resume on re-enable).
  scope :for_enabled_accounts, -> { joins(:account).merge(Account.feature_delayed_automations) }

  def self.schedule(rule:, conversation:, message: nil, at: nil)
    # status_changed_at is only written from this feature onwards, so a conversation that predates it
    # has no status clock. Anchoring on created_at would make every old conversation instantly
    # overdue and fire on the next sweep; leave them for their next status change to arm.
    return if message.nil? && !rule.inactivity_trigger? && conversation.status_changed_at.blank?

    key = arm_episode_key_for(conversation, message, rule: rule)
    anchor = stored_precision(arm_anchor_for(conversation, message, rule: rule, at: at))
    create!(
      automation_rule: rule, conversation: conversation, account_id: conversation.account_id,
      # An inactivity row is about the conversation, not about the message that happened to arm it.
      # Leaving the message out is also what keeps the fire-time condition re-check scoped to the
      # conversation instead of to one message that may be gone by then.
      message_id: rule.inactivity_trigger? ? nil : message&.id,
      episode_key: key, due_at: rule.execution_delay.minutes.since(anchor)
    )
  rescue ActiveRecord::RecordNotUnique
    rearm_or_advance_episode(rule, conversation, key, message, anchor)
  end

  # The episode is already armed. Status episodes keep their first clock (a status change would
  # give a new key), so only message episodes advance or re-arm here.
  def self.rearm_or_advance_episode(rule, conversation, key, message, anchor)
    return advance_inactivity_episode(rule, conversation, key, anchor) if rule.inactivity_trigger?
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

  # Any activity restarts an inactivity count, including the activity that carries no message: a
  # status change, an assignment, a tabulation, an edit.
  #
  # The clock and the row's state are two different things, and this is where they part. The clock
  # always moves, whatever the row is doing, because activity happened and nothing else is going to
  # remember it. The state moves only when no worker holds the row: pulling a live one back to
  # pending would let the sweep claim it and run the same actions alongside the worker. That worker
  # reads the clock when it finishes, so nothing is lost by waiting.
  def self.advance_inactivity_episode(rule, conversation, key, anchor)
    row = find_by!(automation_rule_id: rule.id, conversation_id: conversation.id, episode_key: key)
    row.with_lock do
      # Forward only: a listener running out of order cannot pull the clock back and fire early.
      next if row.activity_at >= anchor

      row.record_activity(anchor)
      next unless row.rearmable_for_inactivity?

      row.update!(status: :pending, skip_reason: nil, due_at: rule.execution_delay.minutes.since(anchor))
    end
  end

  # The wait is measured from when the qualifying event happened, not when this (possibly
  # backlogged or retried) listener runs, so a late dispatch still fires on schedule. Mirrors
  # the timestamps the episode keys track.
  def self.arm_anchor_for(conversation, message, rule: nil, at: nil)
    return inactivity_anchor_for(conversation, message, at) if rule&.inactivity_trigger?

    if message.nil?
      conversation.status_changed_at
    elsif message.incoming?
      conversation.waiting_since.presence || message.created_at
    else
      message.created_at
    end
  end

  # `at` is when the event that armed this said it happened, and that is what the count starts from
  # -- not the row as it reads now, whichever row it is. This job can run long after its event: a
  # retry or a backlog reads a conversation the rule's own actions have since written to, or a
  # message whose updated_at a delivery receipt has since moved, and arms from that. Neither is new
  # activity, and no guard about WHO wrote can see it, because a retry keeps the original actor.
  # The event's own clock is the one thing that cannot move under the job.
  def self.inactivity_anchor_for(conversation, message, at)
    at || activity_anchor_for(conversation, message)
  end

  # The last thing that happened on the conversation. A message is its own timestamp; everything
  # else (a status change, an assignment, a label, a custom attribute) lands on updated_at, and
  # only some of those also bump last_activity_at, so the clock reads whichever is later.
  def self.activity_anchor_for(conversation, message)
    # updated_at, not created_at: an edit is activity, and what it changes is when the message was
    # last written. The two are the same value on a message that just arrived.
    return message.updated_at if message

    [conversation.last_activity_at, conversation.updated_at].compact.max
  end

  # Arming keys differ from the strict fire-time keys wherever current state can already reflect the
  # event the row waits for: MESSAGE_CREATED dispatches asynchronously, so this can run long after
  # the message it arms.
  def self.arm_episode_key_for(conversation, message, rule: nil)
    return INACTIVITY_EPISODE_KEY if rule&.inactivity_trigger?
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

  # These columns hold microseconds, and a timestamp carried by an event keeps its nanoseconds
  # through the queue. Compared against what the column gives back, the SAME event then reads as
  # newer than the row it armed, and a retry resurrects a wait that already ran. An anchor is cut
  # to the column's precision before it is compared or written, so what goes in comes back equal.
  def self.stored_precision(time)
    time&.round(6)
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

  # A run whose worker died holds its row for good: nothing reclaims an `executing` row, because
  # replaying customer-facing actions is worse than dropping them. Activity that landed on it while
  # the worker was still within its timeout is a different matter. It is not the old run, it is the
  # next count, and the worker that would have read it is gone, so without this the rule stays
  # frozen on that conversation until something else happens to arrive. A later arm already takes
  # such a row back; this is the same recovery for the activity that arrived too early to do it.
  def self.recover_abandoned_with_activity!(limit: 1000)
    recoverable_abandoned.for_enabled_accounts.order(:due_at).limit(limit).count(&:recover_abandoned_run!)
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
    # An inactivity episode never ends, it only restarts: what would cancel it is activity, and
    # that is read from the clock (`inactivity_due_at`) rather than from a key that changes.
    return true if automation_rule&.inactivity_trigger?

    self.class.episode_key_for(conversation, message) == episode_key
  end

  # The latest activity this row knows about. Both sources, because they are written on different
  # paths: a listener records one, and a worker that pushed the deadline forward moved the other
  # without recording anything. Reading the older of the two would let an event the current deadline
  # already covers pass the forward-only guard and pull the clock back. Never nil, so callers
  # compare times rather than handling absence.
  def activity_at
    [activity_seen_at, armed_anchor].compact.max
  end

  # The anchor the current deadline was built from.
  def armed_anchor
    due_at - automation_rule.execution_delay.minutes
  end

  # Writes the clock without touching updated_at, which is the worker's lock: renewing it on every
  # message would keep a dead worker looking alive and freeze the row in `executing` for good.
  def record_activity(anchor)
    update_column(:activity_seen_at, anchor) # rubocop:disable Rails/SkipsModelValidations -- see above
  end

  # When the conversation moved after this row was armed, the time it should fire at instead.
  # Nil when nothing moved (or when this row is not an inactivity wait), which is the case that
  # actually runs the actions. Some activity never reaches a listener -- an activity message, a
  # reply another automation sent, a custom attribute another rule wrote -- so the clock is read
  # here rather than trusted from the arm, and it is read the same way the arm reads it: a write
  # that lands on updated_at alone is still activity.
  #
  # This reads every write, including one from another wait on silence, which the ARM excludes. The
  # asymmetry is the point, because the two can do different things: this one can only push a
  # deadline forward, so its worst outcome is waiting longer than asked, while the arm can take a
  # terminal row back to pending and cause an action that would otherwise never happen -- two such
  # waits arming each other answer each other for ever. Forward on any write; a new count only from
  # writing that is not itself a wait on silence. Symmetry is also not available: last_activity_at
  # and updated_at are columns with no provenance, and at fire time, in another job, nothing on the
  # conversation says which rule wrote them.
  #
  # `conversation_anchor` is that reading taken at another moment, which is what a caller that has
  # since written to the conversation itself passes: its own writes are not activity, and reading
  # the column after them would restart the count on the rule's own run.
  def inactivity_due_at(armed_for: due_at, conversation_anchor: nil)
    return nil unless automation_rule&.inactivity_trigger?

    delay = automation_rule.execution_delay.minutes
    # Both sources: what a listener recorded on the row, and what the conversation itself says, for
    # the activity that reaches no listener at all.
    conversation_anchor ||= self.class.activity_anchor_for(conversation, nil)
    anchor = [conversation_anchor, activity_seen_at].compact.max
    return nil unless anchor > armed_for - delay

    anchor + delay
  end

  # A new stretch of activity starts a new count, including after a run: the lead was released,
  # somebody touched the conversation again, and it can go quiet again. A live worker is the one
  # case that keeps its status, and an abandoned `executing` row would otherwise freeze the rule
  # for good.
  def rearmable_for_inactivity?
    return true if pending? || skipped? || executed? || stale_processing?

    executing? && abandoned_run?
  end

  # Starts the next count on a row whose worker died, and only that. It reads what a listener
  # recorded and never the conversation's own columns, which the other clock readings do: the dead
  # worker wrote to that conversation before it died and there is no snapshot left to subtract, so
  # reading it here would take the run's own message for new activity and run the actions a second
  # time. What a listener recorded cannot be the run's own writing, which is the arm's whole job.
  def recover_abandoned_run!
    with_lock do
      next false unless abandoned_run? && automation_rule&.inactivity_trigger?
      # Strictly newer than the arm this row is running on, or it is activity already consumed.
      next false unless activity_seen_at && activity_seen_at > armed_anchor

      update!(status: :pending, skip_reason: nil,
              due_at: activity_seen_at + automation_rule.execution_delay.minutes)
      true
    end
  end

  # Marked `executing` long enough ago that the worker holding it is gone.
  def abandoned_run?
    executing? && updated_at < STALE_PROCESSING_TIMEOUT.ago
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
