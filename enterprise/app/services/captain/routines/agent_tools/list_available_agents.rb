class Captain::Routines::AgentTools::ListAvailableAgents < Captain::Routines::AgentTools::Base
  description 'List agents currently available for an optional inbox or team'
  param :inbox, type: 'string', desc: 'Inbox name or ID', required: false
  param :team, type: 'string', desc: 'Team name or ID', required: false

  def name = 'list_available_agents'

  def perform(tool_context, inbox: nil, team: nil)
    perform_operation(tool_context, 'agents.list_available', inbox: inbox, team: team)
  end
end
