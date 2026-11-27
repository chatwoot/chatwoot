json.agent_bot do
  json.partial! 'api/v1/models/agent_bot', formats: [:json], resource: AgentBotPresenter.new(@agent_bot) if @agent_bot.present?
end
