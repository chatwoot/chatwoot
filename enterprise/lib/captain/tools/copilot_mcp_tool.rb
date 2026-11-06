# An MCP tool where an admin or an agent is the user: the playground and reply suggestions. The model fills the values
# a customer proves with the ones it was given, and the result says when they are not what the customer proved.
# Values the customer does not prove, such as a fixed value, are still set by Chatwoot.
class Captain::Tools::CopilotMcpTool < Captain::Tools::McpTool
  def self.model_fills_verified_values?
    true
  end

  private

  def arguments_for(tool_context, params)
    tool_arguments(tool_context).fill_unproven(params)
  end

  def annotate(result, tool_context, params)
    tool_arguments(tool_context).verified?(params) ? result : "#{result}\n\n#{Captain::Tools::CopilotHttpTool::UNVERIFIED_VALUE_NOTE}"
  end

  def tool_arguments(tool_context)
    Captain::ToolArguments.new(@mcp_tool, find_conversation(tool_context.state))
  end
end
