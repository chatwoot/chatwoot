json.array! @agent_bots do |agent_bot|
  json.partial! 'api/v1/models/agent_bot.json.jbuilder', resource: agent_bot
end
