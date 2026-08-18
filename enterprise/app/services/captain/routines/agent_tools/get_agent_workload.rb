class Captain::Routines::AgentTools::GetAgentWorkload < Captain::Routines::AgentTools::Base
  description 'Get current assignment and capacity information for an account agent'
  param :agent, type: 'string', desc: 'Agent name, email, or ID'

  def name = 'get_agent_workload'

  def perform(tool_context, agent:)
    perform_operation(tool_context, 'agents.get_workload', agent: agent)
  end
end
