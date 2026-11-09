# An approved MCP tool that Captain cannot use in this run, because its server changed it, no longer lists it, or could
# not be listed. The agent keeps the tool, so a scenario that names it still matches the tools the agent has, and a
# call answers that the tool is unavailable. The call never reaches the server.
#
# Known limit: this class inherits McpTool for its name, description, schema and read_only?, and overrides the two
# methods that reach the server, perform and for_copilot. A new McpTool method that reaches the server is inherited
# too, so it must be overridden here as well. Without an override it raises on the nil connection instead of calling
# the server.
class Captain::Tools::UnavailableMcpTool < Captain::Tools::McpTool
  UNAVAILABLE = 'This tool is unavailable right now. Do not call it again in this conversation.'.freeze

  def perform(tool_context, **_params)
    failure_result(UNAVAILABLE, tool_context.state)
  end

  # McpTool builds a working Copilot tool from the connection, so this tool stays as it is
  def for_copilot
    self
  end
end
