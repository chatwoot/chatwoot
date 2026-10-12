class Captain::Copilot::Actions::AssignAgent < Captain::Copilot::Actions::BaseAction
  NAME = 'assign_agent'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = 'Assign each conversation to an agent. Arguments: agent_id, the user ID of the agent from the list of agents in your ' \
                'instructions. The agent must be able to take conversations in each inbox.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[agent_id],
    properties: { agent_id: { type: 'integer', minimum: 1 } }
  }.deep_stringify_keys.freeze

  # Uses the dashboard's assignment path, so a conversation a bot holds is opened and the activity message names the agent.
  def perform(conversation)
    return 'skipped' if conversation.assignee_id == agent.id

    # Inbox members and administrators, the agents the dashboard offers as assignees for the inbox.
    unless conversation.inbox.assignable_agents.include?(agent)
      raise Captain::Copilot::ActionNotApplicableError, "#{agent.name} cannot be assigned conversations in #{conversation.inbox.name}"
    end

    Conversations::AssignmentService.new(conversation: conversation, assignee_id: agent.id).perform
    'applied'
  end

  def card_details
    { agent_name: agent.name }
  end

  private

  def agent
    @agent ||= @account.users.find_by(id: @arguments['agent_id'])
  end

  def validate!
    return if agent

    agents = @account.users.order(:name).limit(100).map { |user| "#{user.name} (ID #{user.id})" }
    raise ArgumentError, "No agent with user ID #{@arguments['agent_id']} in this account. Agents: #{agents.join(', ')}"
  end
end
