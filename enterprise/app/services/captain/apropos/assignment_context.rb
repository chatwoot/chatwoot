class Captain::Apropos::AssignmentContext
  CONTRACT = {
    arguments: { reference: 'inbox ref: {type: "inboxes", id: integer}', cursor: 'optional nonnegative integer, default 0' },
    returns: 'inbox_id, feature flags, assignment_policy (or null), legacy_auto_assignment_config, items, next_cursor. ' \
             'Up to 50 manually assignable agents per page, ordered by database ID; next_cursor=false ends pagination.',
    fields: {
      availability: 'Account membership status: online, offline, busy. online_inbox_member uses live Chatwoot presence and inbox membership.',
      manual_assignment_eligible: 'Passes inbox.assignable_agents, including account administrators. Not automatic eligibility.',
      capacity_policy: 'Assigned capacity policy id/name/exclusion_rules, or null. Exclusions describe policy, not a filter on this agent list.',
      configured_inbox_limit: 'Policy limit for this inbox, or null for unlimited under that policy. Not a zero limit.',
      configured_remaining_slots: 'max(limit minus open assignments in this inbox, 0), or null if unlimited. Not a reservation.',
      has_capacity_under_policy: 'Authoritative CapacityService result. No policy or no inbox limit means true, independent of feature enablement.',
      inbox_member_with_assignment_capacity: 'inbox.member_ids_with_assignment_capacity result under current legacy/v2 feature behavior.',
      within_assignment_rate_limit: 'Authoritative AutoAssignment::RateLimiter result, separate from open-conversation capacity.',
      assignment_policy: 'Stored enablement, order, priority, distribution limits and age exclusion. Null means no explicit policy.'
    },
    usage: 'Read all pages before ranking. Intersect with the user-selected agent pool. Capacity and presence can change before assignment.',
    boundaries: 'Read only; does not choose, reserve, or assign an agent. Automatic assignment also considers enablement, team restrictions, ' \
                'queue exclusions, and distribution order. No single returned flag guarantees automatic assignment. ' \
                'Manual assign-agent checks inbox eligibility, not automatic policy capacity or rate limits.',
    failures: 'Wrong target, invalid cursor, or inaccessible inbox fails. Redis/database failures are surfaced, not treated as zero capacity.',
    retry: 'Safe to reread; values are live snapshots. No LLM call or writes.'
  }.freeze
  POLICY_FIELDS = %w[id name enabled assignment_order conversation_priority fair_distribution_limit fair_distribution_window
                     exclude_older_than_hours].freeze

  def initialize(data:)
    @data = data
    @capacity_service = Enterprise::AutoAssignment::CapacityService.new
  end

  def call(reference, cursor = 0)
    validate_request!(reference, cursor)
    @inbox = @data.resolve(reference)
    agents = @inbox.assignable_agents.select { |agent| agent.id > cursor }.sort_by(&:id).first(Captain::Apropos::DataAccess::PAGE_SIZE + 1)
    page = agents.first(Captain::Apropos::DataAccess::PAGE_SIZE)
    load_agent_context(page.map(&:id))
    policy_state.merge(
      'items' => page.map { |agent| agent_state(agent) },
      'next_cursor' => agents.size > page.size ? page.last.id : false
    )
  end

  private

  def validate_request!(reference, cursor)
    raise Captain::Apropos::Error, 'assignment-context requires an inbox reference' unless reference.fetch('type') == 'inboxes'
    raise Captain::Apropos::Error, 'cursor must be a nonnegative integer' unless cursor.is_a?(Integer) && cursor >= 0
  end

  def load_agent_context(ids)
    @online_members = @inbox.available_agents.pluck(:user_id)
    @capacity_members = @inbox.member_ids_with_assignment_capacity
    @counts = @inbox.conversations.open.where(assignee_id: ids).group(:assignee_id).count
    @memberships = @inbox.account.account_users.where(user_id: ids)
                         .includes(agent_capacity_policy: :inbox_capacity_limits).index_by(&:user_id)
  end

  def policy_state
    {
      'inbox_id' => @inbox.id, 'auto_assignment_enabled' => @inbox.enable_auto_assignment?,
      'assignment_v2_enabled' => @inbox.auto_assignment_v2_enabled?,
      'advanced_assignment_enabled' => @inbox.account.feature_enabled?('advanced_assignment'),
      'assignment_policy' => @inbox.assignment_policy&.attributes&.slice(*POLICY_FIELDS),
      'legacy_auto_assignment_config' => @inbox.auto_assignment_config
    }
  end

  def agent_state(agent)
    membership = @memberships.fetch(agent.id)
    count = @counts.fetch(agent.id, 0)
    policy = membership.agent_capacity_policy
    limit = policy&.inbox_capacity_limits&.find { |item| item.inbox_id == @inbox.id }&.conversation_limit
    limiter = AutoAssignment::RateLimiter.new(inbox: @inbox, agent: agent)
    {
      'ref' => { 'type' => 'agents', 'id' => agent.id }, 'name' => agent.name,
      'availability' => membership.availability, 'online_inbox_member' => @online_members.include?(agent.id),
      'manual_assignment_eligible' => true, 'open_conversations_in_inbox' => count,
      'capacity_policy' => policy&.attributes&.slice('id', 'name', 'exclusion_rules'),
      'configured_inbox_limit' => limit, 'configured_remaining_slots' => limit ? [limit - count, 0].max : nil,
      'has_capacity_under_policy' => @capacity_service.agent_has_capacity?(agent, @inbox),
      'inbox_member_with_assignment_capacity' => @capacity_members.include?(agent.id),
      'within_assignment_rate_limit' => limiter.within_limit?
    }
  end
end
