class SalesRouting::AgentSelector
  pattr_initialize [:conversation!, :configuration!, :round!]

  def candidates(online_agents)
    agents = online_agents.where(user_id: active_member_ids)
    return agents unless conversation.team_id
    return agents.none unless conversation.team.allow_auto_assign?

    team_agents = agents.where(user_id: conversation.team.members.select(:id))
    # A saturated but online store waits for capacity; fallback is only for an offline store.
    return team_agents if team_agents.exists? || configuration.store_for_team(conversation.team_id).nil?

    agents
  end

  def select(agents)
    return if agents.empty?

    preferred = route['preferred_agent_id']
    agent = agents.find { |member| member.user_id == preferred }&.user || balanced_agent(agents)
    round << agent.id
    agent
  end

  def assignment_attributes(agent)
    selected_team = team_for_agent(agent)
    fallback = route['store'].present? && configuration.team_for(route['store']).id != selected_team.id
    updated_route = route.merge('assignment_rule' => fallback ? 'fallback-geral' : route.fetch('rule'))
    attributes = { additional_attributes: conversation.additional_attributes.merge(SalesRouting::Classifier::ATTRIBUTES_KEY => updated_route) }
    attributes[:team] = selected_team if conversation.team_id.nil? || fallback
    attributes
  end

  private

  def active_member_ids
    active_ids = configuration.teams.values.select(&:allow_auto_assign?).flat_map { |team| team.members.map(&:id) }
    configuration.member_ids & active_ids
  end

  def team_for_agent(agent)
    configuration.teams.values.find { |team| team.members.map(&:id).include?(agent.id) }
  end

  def route
    conversation.additional_attributes.fetch(SalesRouting::Classifier::ATTRIBUTES_KEY)
  end

  def balanced_agent(agents)
    remaining = agents.reject { |member| round.include?(member.user_id) }
    if remaining.empty?
      round.clear
      remaining = agents
    end
    AutoAssignment::RoundRobinSelector.new(inbox: conversation.inbox).select_agent(least_busy(remaining))
  end

  def least_busy(agents)
    counts = conversation.inbox.conversations.open.unattended.where(assignee_id: agents.map(&:user_id)).group(:assignee_id).count
    minimum = agents.map { |member| counts.fetch(member.user_id, 0) }.min
    agents.select { |member| counts.fetch(member.user_id, 0) == minimum }
  end
end
