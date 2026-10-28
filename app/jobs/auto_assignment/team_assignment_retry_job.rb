# Team auto-assignment otherwise runs only when a conversation's team is set; this
# retries it for an account's waiting team conversations once an agent is online.
class AutoAssignment::TeamAssignmentRetryJob < ApplicationJob
  queue_as :default

  BATCH_LIMIT = 100
  COALESCE_WINDOW = 10.seconds

  # Reconnecting agents resubscribe within seconds of each other; one delayed pass serves them all.
  def self.enqueue_for_account(account)
    key = format(::Redis::Alfred::TEAM_ASSIGNMENT_DEBOUNCE_KEY, account_id: account.id)
    return unless ::Redis::Alfred.set(key, true, nx: true, ex: COALESCE_WINDOW)

    set(wait: COALESCE_WINDOW).perform_later(account: account)
  end

  def perform(account:)
    conversations = waiting_conversations(account).to_a
    assigned = conversations.count do |conversation|
      inbox = conversation.inbox
      if inbox.auto_assignment_v2_enabled? && inbox.enable_auto_assignment?
        # Inboxes on Assignment V2 bulk assignment retry their team conversations there.
        AutoAssignment::AssignmentJob.enqueue_for_inbox(inbox.id)
        next false
      end

      Current.executed_by = conversation.team
      allowed_agent_ids = inbox.member_ids_with_assignment_capacity & team_member_ids(conversation.team)
      AutoAssignment::AgentAssignmentService.new(conversation: conversation, allowed_agent_ids: allowed_agent_ids).perform
    end
    # A full pass that made progress leaves more behind; legacy inboxes have no periodic sweep.
    self.class.enqueue_for_account(account) if conversations.size == BATCH_LIMIT && assigned.positive?
  ensure
    Current.executed_by = nil
  end

  private

  def waiting_conversations(account)
    account.conversations
           .open
           .unassigned
           .where(team_id: teams_with_online_members(account))
           .where('conversations.last_activity_at >= ?', AssignmentPolicy::DEFAULT_EXCLUDE_OLDER_THAN_HOURS.hours.ago)
           .includes(:inbox, :team)
           .order(created_at: :asc)
           .limit(BATCH_LIMIT)
  end

  def teams_with_online_members(account)
    teams = account.teams.where(allow_auto_assign: true)
    return [] if teams.none?

    online_user_ids = OnlineStatusTracker.get_available_users(account.id).select { |_id, status| status.eql?('online') }.keys
    teams.joins(:team_members).where(team_members: { user_id: online_user_ids }).distinct.pluck(:id)
  end

  def team_member_ids(team)
    @team_member_ids ||= {}
    @team_member_ids[team.id] ||= team.members.ids
  end
end
