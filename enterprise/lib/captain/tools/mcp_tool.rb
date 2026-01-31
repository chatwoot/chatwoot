require 'agents'

class Captain::Tools::McpTool < Agents::Tool
  def initialize(assistant, mcp_server, tool_name)
    @assistant = assistant
    @mcp_server = mcp_server
    @tool_name = tool_name
    super()
  end

  def active?
    @mcp_server.enabled? && @mcp_server.connection_connected?
  end

  def perform(_tool_context, **params)
    return 'MCP server is disabled' unless @mcp_server.enabled?

    client = Captain::Mcp::ClientService.new(@mcp_server)
    client.call_tool(@tool_name, params)

  rescue Captain::Mcp::ConnectionError => e
    Rails.logger.error("MCP connection error for #{@tool_name}: #{e.message}")
    "MCP server connection error: #{e.message}"
  rescue Captain::Mcp::ToolExecutionError => e
    Rails.logger.error("MCP tool execution error for #{@tool_name}: #{e.message}")
    "Tool execution failed: #{e.message}"
  rescue StandardError => e
    Rails.logger.error("MCP tool error for #{@tool_name}: #{e.class} - #{e.message}")
    'An error occurred while executing the MCP tool'
  end
end
