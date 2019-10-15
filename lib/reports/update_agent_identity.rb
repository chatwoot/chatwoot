# frozen_string_literal: true

class Reports::UpdateAgentIdentity < Reports::UpdateIdentity
  attr_reader :agent

  def initialize(account, agent, timestamp = Time.now)
    super(account, timestamp)
    @agent = agent
    @identity = ::AgentIdentity.new(agent.id, tags: { account_id: account.id })
  end
end
