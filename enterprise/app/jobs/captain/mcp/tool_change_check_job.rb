# Lists the tools of every enabled MCP server with approved tools, so admins see a changed tool before a customer asks.
# Captain already skips a changed tool at the start of each run. This job only records each approved tool's review state.
#
# Known limit: one run lists every server in turn. A slow server delays the servers after it, and an error that is not
# a Connection error ends the run. As the number of servers grows, this job should enqueue one job per server instead,
# as Channels::Whatsapp::HealthSyncSchedulerJob does.
class Captain::Mcp::ToolChangeCheckJob < ApplicationJob
  queue_as :low

  def perform
    Captain::McpServer.enabled.for_enabled_accounts.where(id: Captain::McpTool.select(:mcp_server_id)).find_each do |server|
      connection = Captain::Mcp::Connection.new(server)
      server.record_live_tools(connection.recent_tool_definitions)
    rescue *Captain::Mcp::Connection::ERRORS => e
      Rails.logger.warn("Captain MCP tool check failed for server #{server.id}: #{e.class} - #{e.message}")
    end
  end
end
