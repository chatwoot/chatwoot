json.agent_bot do
  json.partial! 'api/v1/models/agent_bot.json.jbuilder', resource: @agent_bot if @agent_bot.present?
end
