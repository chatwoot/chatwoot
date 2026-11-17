# An MCP tool in a conversation where a customer is the user. Parameters with a source always carry the value
# Chatwoot read, and the tool does not run when a value the customer must prove is missing.
class Captain::Tools::PublicMcpTool < Captain::Tools::McpTool
  private

  def arguments_for(tool_context, params)
    Captain::ToolArguments.new(@mcp_tool, find_conversation(tool_context.state)).fill(params)
  end
end
