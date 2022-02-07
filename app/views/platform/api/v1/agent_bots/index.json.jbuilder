json.array! @resources do |resource|
  json.partial! 'platform/api/v1/models/agent_bot.json.jbuilder', resource: resource.permissible
end
