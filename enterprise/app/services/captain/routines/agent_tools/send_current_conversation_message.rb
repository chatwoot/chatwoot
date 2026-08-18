class Captain::Routines::AgentTools::SendCurrentConversationMessage < Captain::Routines::AgentTools::Base
  OPERATIONS = {
    'reply' => 'conversations.send_reply',
    'private_note' => 'conversations.add_private_note'
  }.freeze

  description 'Send a customer-visible reply or add an internal private note to the current conversation'
  params(
    type: 'object',
    properties: {
      type: { type: 'string', enum: OPERATIONS.keys },
      content: { type: 'string', minLength: 1 },
      mention_agents: { type: 'array', items: { type: 'string' } },
      mention_current_assignee: { type: 'boolean' }
    },
    required: %w[type content],
    additionalProperties: false
  )

  def name = 'send_current_conversation_message'

  def perform(tool_context, type:, content:, mention_agents: [], mention_current_assignee: false)
    perform_operation(
      tool_context,
      OPERATIONS.fetch(type),
      conversation_id: current_conversation_id(tool_context),
      content: message_content(tool_context, content, mention_agents, mention_current_assignee)
    )
  end

  private

  def message_content(tool_context, content, mention_agents, mention_current_assignee)
    agents = Array(mention_agents).map { |value| resolve_agent(tool_context, value) }
    agents << current_conversation(tool_context).assignee if ActiveModel::Type::Boolean.new.cast(mention_current_assignee)
    agents = agents.compact.uniq(&:id)
    return content if agents.empty?

    mentions = agents.index_by { |agent| "agent_#{agent.id}" }.transform_values do |agent|
      { 'id' => agent.id, 'name' => agent.name }
    end
    segments = mentions.keys.flat_map do |mention|
      [{ 'type' => 'mention', 'mention' => mention }, { 'type' => 'text', 'text' => ' ' }]
    end
    segments << { 'type' => 'text', 'text' => content }

    { 'type' => 'rich_message', 'segments' => segments, 'mentions' => mentions }
  end

  def resolve_agent(tool_context, value)
    scope = runtime(tool_context).account.users
    return scope.find(value) if value.to_s.match?(/\A\d+\z/)

    scope.where('LOWER(users.name) = :value OR LOWER(users.email) = :value', value: value.to_s.downcase).sole
  end
end
