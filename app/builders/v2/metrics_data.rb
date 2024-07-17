class V2::MetricsData
  attr_accessor :total_conversations, :total_agents, :base_price,
                :extra_conversation_cost, :extra_agent_cost, :total_price

  def initialize(total_conversations:, total_agents:, base_price:,
                 extra_conversation_cost:, extra_agent_cost:, total_price:)
    @total_conversations = total_conversations
    @total_agents = total_agents
    @base_price = base_price
    @extra_conversation_cost = extra_conversation_cost
    @extra_agent_cost = extra_agent_cost
    @total_price = total_price
  end

  def to_h
    {
      total_conversations: @total_conversations,
      total_agents: @total_agents,
      base_price: @base_price,
      extra_conversation_cost: @extra_conversation_cost,
      extra_agent_cost: @extra_agent_cost,
      total_price: @total_price
    }
  end
end
