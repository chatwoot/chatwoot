json.payload do
  owners = @assignable_agents.map { |agent| { type: 'User', resource: agent } }
  owners += @agent_bots.map { |agent_bot| { type: 'AgentBot', resource: agent_bot } }

  json.array! owners do |owner|
    if owner[:type] == 'User'
      json.partial! 'api/v1/models/agent', formats: [:json], resource: owner[:resource]
      json.assignee_type 'User' if @include_ai_assignees
    else
      json.partial! 'api/v1/models/agent_bot_slim', formats: [:json], resource: owner[:resource]
      json.assignee_type 'AgentBot'
      json.icon 'i-lucide-bot'
      json.availability_status 'offline'
    end
  end

  json.partial! 'enterprise/api/v1/accounts/assignable_agents/assistants' if ChatwootApp.enterprise?
end
