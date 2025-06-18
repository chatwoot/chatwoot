# frozen_string_literal: true

# MCP Server Auto-Setup Initializer
# Automatically sets up MCP servers when the application starts

Rails.application.config.after_initialize do
  # Only setup in development, production, or when explicitly enabled
  if Rails.env.development? || Rails.env.production? || ENV['MCP_AUTO_SETUP'] == 'true'
    begin
      # Use a background job or thread to avoid blocking application startup
      Thread.new do
        require Rails.root.join('lib/mcp_client_service')
        service = McpClientService.instance
        service.initialize_default_servers!

        Rails.logger.info '[MCP Setup] ✅ MCP initialization thread completed'
      end

      Rails.logger.info '[MCP Setup] ✅ MCP server initialization scheduled successfully'

    rescue StandardError => e
      Rails.logger.error "[MCP Setup] ❌ Failed to schedule MCP setup: #{e.message}"
      Rails.logger.error "[MCP Setup] Backtrace: #{e.backtrace.first(3).join(', ')}"
      # Don't fail application startup if MCP setup fails
    end
  else
    Rails.logger.info "[MCP Setup] ⏭️ Skipping MCP setup (environment: #{Rails.env})"
  end
end

# MCP initialization is now handled by the McpClientService