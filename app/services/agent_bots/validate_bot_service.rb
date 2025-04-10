class AgentBots::ValidateBotService
  pattr_initialize [:agent_bot]
  def perform
    # Only webhook bots are supported now
    # All webhook bots are valid by default
    true
  end
end
