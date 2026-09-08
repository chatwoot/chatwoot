json.array! @resources do |resource|
  bot = resource.permissible
  next if bot.nil?

  json.partial! 'platform/api/v1/models/agent_bot', formats: [:json], resource: bot
end
