# Lists the tools of every enabled MCP server with approved tools, so admins see a changed tool before a customer asks.
# Captain already skips a changed tool at the start of each run. This job only marks the server for review.
class Captain::Mcp::ToolChangeCheckJob < ApplicationJob
  queue_as :low

  def perform
    Captain::McpServer.enabled.where(id: Captain::McpTool.select(:mcp_server_id)).find_each do |server|
      next unless server.account.feature_enabled?(Captain::McpServer::FEATURE_FLAG)

      connection = Captain::Mcp::Connection.new(server)
      server.record_tool_changes(connection.track_status { connection.tool_definitions })
    rescue *Captain::Mcp::Connection::ERRORS => e
      Rails.logger.warn("Captain MCP tool check failed for server #{server.id}: #{e.class} - #{e.message}")
    end
  end
end
