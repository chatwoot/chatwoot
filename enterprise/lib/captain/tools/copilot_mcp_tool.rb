# An MCP tool where an admin or an agent is the user: the playground and reply suggestions. The model fills the values
# a customer proves with the ones it was given, and the result says when they are not what the customer proved.
# Values the customer does not prove, such as a fixed value, are still set by Chatwoot.
class Captain::Tools::CopilotMcpTool < Captain::Tools::McpTool
  def self.model_fills_verified_values?
    true
  end

  def perform(tool_context, **params)
    arguments = Captain::ToolArguments.new(@mcp_tool, find_conversation(tool_context.state))
    result = super(tool_context, **arguments.fill_unproven(params))
    arguments.verified?(params) ? result : "#{result}\n\n#{Captain::Tools::CopilotHttpTool::UNVERIFIED_VALUE_NOTE}"
  end
end
