class Captain::Mcp::CacheRefreshJob < ApplicationJob
  queue_as :low

  def perform(mcp_server_id)
    mcp_server = Captain::McpServer.find_by(id: mcp_server_id)
    return unless mcp_server&.enabled?

    discovery_service = Captain::Mcp::DiscoveryService.new(mcp_server)
    discovery_service.refresh_tools
  rescue Captain::Mcp::Error => e
    Rails.logger.error("MCP cache refresh failed for server #{mcp_server_id}: #{e.message}")
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("MCP server #{mcp_server_id} not found for cache refresh")
  end
end
