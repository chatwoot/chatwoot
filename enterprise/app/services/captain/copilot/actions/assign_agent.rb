class Captain::Copilot::Actions::AssignAgent < Captain::Copilot::Actions::BaseAction
  NAME = 'assign_agent'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = 'Assign each conversation to an agent, or remove its agent. Arguments: agent_ids, user IDs from ' \
                'get_account_directory, or null to unassign. With several agents, the conversations are split evenly between ' \
                'them. A conversation is not assigned to an agent who is not a member of its inbox.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[agent_ids],
    properties: { agent_ids: { type: %w[array null], minItems: 1, maxItems: 10, uniqueItems: true, items: { type: 'integer', minimum: 1 } } }
  }.deep_stringify_keys.freeze

  # Target number i goes to agent number i mod n in the frozen target order, so the split on the card never changes.
  def proposal_values(ids)
    return {} unless agent_ids

    ids.each_with_index.to_h { |id, index| [id.to_s, agent_ids[index % agent_ids.size]] }
  end

  # Uses the dashboard's assignment path, so a pending conversation a bot holds opens and the activity message names the agent.
  def perform(conversation)
    agent = agents[@proposal_values[conversation.id.to_s]]
    return :skipped if conversation.assignee_id == agent&.id

    # The dashboard offers only inbox members and administrators as assignees.
    if agent && conversation.inbox.assignable_agents.exclude?(agent)
      raise Captain::Copilot::ActionNotApplicableError, "#{agent.name} is not a member of the #{conversation.inbox.name} inbox"
    end

    Conversations::AssignmentService.new(conversation: conversation, assignee_id: agent&.id).perform
    :applied
  end

  def card(ids)
    return { summary: 'UNASSIGN_AGENT' } unless agent_ids
    return super.merge(values: { agents: agents[agent_ids.first].name }) if agent_ids.one?

    counts = proposal_values(ids).values.tally
    super.merge(values: { agents: agent_ids.map { |id| "#{agents[id].name} (#{counts[id].to_i})" }.join(', ') })
  end

  private

  def agent_ids
    @arguments['agent_ids']
  end

  def agents
    @agents ||= @account.users.where(id: agent_ids).index_by(&:id)
  end

  def validate!
    unknown = agent_ids.to_a - agents.keys
    return if unknown.empty?

    directory = @account.users.order(:name).limit(100).map { |user| "#{user.name} (ID #{user.id})" }
    raise ArgumentError, "No agent with user ID #{unknown.join(', ')} in this account. Agents: #{directory.join(', ')}"
  end
end
