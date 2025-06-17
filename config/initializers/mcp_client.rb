# frozen_string_literal: true

# MCP Client Initializer
# This initializer sets up the Model Context Protocol client service
# for connecting to external MCP servers like Mintlify documentation.

# Initialize the MCP client service
Rails.application.config.after_initialize do
  # Initialize the MCP client service singleton
  McpClientService.instance
  Rails.logger.info('[MCP] MCP Client Service initialized successfully')

rescue StandardError => e
  Rails.logger.error("[MCP] Failed to initialize MCP service: #{e.message}")

  # Don't crash the application, just log the error
  Rails.logger.warn('[MCP] MCP integration disabled due to initialization error')
end

# Simple health check method for console debugging
if Rails.env.development?
  Rails.application.config.after_initialize do
    def mcp_health_check
      service = McpClientService.instance
      stats = service.stats

      Rails.logger.debug 'MCP Service Health Check'
      Rails.logger.debug '======================='
      Rails.logger.debug { "Clients: #{stats[:clients].join(', ')}" }
      Rails.logger.debug 'Connection Stats:'
      stats[:connection_stats].each do |server, stat|
        Rails.logger.debug "  #{server}: #{stat[:total_calls]} calls, #{stat[:successful_calls]} successful"
      end
    rescue StandardError => e
      Rails.logger.debug { "Health check failed: #{e.message}" }
    end
  end
end
