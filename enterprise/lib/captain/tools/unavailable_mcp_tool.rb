# An approved MCP tool that Captain cannot use in this run, because its server rejected the saved credentials. The
# agent keeps the tool, so a scenario that names it still matches the tools the agent has, and a call answers that the
# tool is unavailable. It has no connection and never reaches the server.
class Captain::Tools::UnavailableMcpTool < Captain::Tools::BasePublicTool
  # The model fills nothing that Chatwoot proves, because the tool never runs
  def self.model_fills_verified_values?
    false
  end

  def initialize(assistant, mcp_tool, _connection)
    @mcp_tool = mcp_tool
    super(assistant)
  end

  def perform(tool_context, **_params)
    failure_result(Captain::Tools::McpTool::UNAVAILABLE, tool_context.state)
  end

  def read_only?
    @mcp_tool.read_only?
  end
end
