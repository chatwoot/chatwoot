class Captain::Mcp::DiscoveryService
  attr_reader :mcp_server

  def initialize(mcp_server)
    @mcp_server = mcp_server
    @client = Captain::Mcp::ClientService.new(mcp_server)
  end

  def refresh_tools
    tools = @client.list_tools
    @mcp_server.update!(
      cached_tools: tools,
      cache_refreshed_at: Time.current
    )
    tools
  rescue StandardError => e
    Rails.logger.error("MCP tool discovery failed for #{@mcp_server.slug}: #{e.class} - #{e.message}")
    raise Captain::Mcp::Error, "Failed to discover tools: #{e.message}"
  end

  def connect_and_discover
    result = @client.connect
    raise Captain::Mcp::ConnectionError, result.error unless result.success?

    refresh_tools
  end
end
