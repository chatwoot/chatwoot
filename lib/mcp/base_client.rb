# frozen_string_literal: true

require 'mcp_client'

module Mcp
  # Base class for all MCP clients
  # Provides common functionality and interface for MCP connections
  class BaseClient
    class ConnectionError < StandardError; end
    class ConfigurationError < StandardError; end
    class ToolCallError < StandardError; end

    attr_reader :name, :config, :client, :connected

    def initialize(name, config = {})
      @name = name
      @config = default_config.merge(config)
      @client = nil
      @connected = false
      @wrapper_script = nil

      post_initialize_setup
    end

    # Connect to the MCP server
    def connect!
      Rails.logger.info("[Mcp::#{self.class.name}] Starting connection to #{@name}...")
      connection_start = Time.current

      validate_config!
      @client = create_client
      @connected = true

      duration = Time.current - connection_start
      Rails.logger.info("[Mcp::#{self.class.name}] Connected successfully in #{duration.round(3)}s")

      if @config[:test_on_connect]
        Rails.logger.debug { "[Mcp::#{self.class.name}] Testing connection..." }
        test_connection
      end

    rescue StandardError => e
      @connected = false
      Rails.logger.error("[Mcp::#{self.class.name}] Connection failed: #{e.message}")
      Rails.logger.debug { "[Mcp::#{self.class.name}] Error details: #{e.backtrace.first(2).join(', ')}" }
      raise ConnectionError, "Failed to connect: #{e.message}"
    end

    # Disconnect from the MCP server
    def disconnect!
      @client = nil
      @connected = false

      # Clean up wrapper script if it exists
      cleanup_wrapper_script

      Rails.logger.debug { "[Mcp::#{self.class.name}] Disconnected" }
    end

    # Check if connected
    def connected?
      @connected && @client.present?
    end

    # Call a tool on the MCP server
    def call_tool(tool_name, arguments = {})
      ensure_connected!

      Rails.logger.debug { "[Mcp::#{self.class.name}] Calling tool: #{tool_name}" }
      result = @client.call_tool(tool_name, arguments)
      Rails.logger.debug { "[Mcp::#{self.class.name}] Tool call successful" }

      result
    rescue StandardError => e
      Rails.logger.error("[Mcp::#{self.class.name}] Tool call failed: #{e.message}")
      raise ToolCallError, "Failed to call tool #{tool_name}: #{e.message}"
    end

    # List available tools
    def list_tools
      ensure_connected!

      tools = @client.list_tools || []
      Rails.logger.debug { "[Mcp::#{self.class.name}] Found #{tools.length} tools" }

      tools
    rescue StandardError => e
      Rails.logger.error("[Mcp::#{self.class.name}] Failed to list tools: #{e.message}")
      []
    end

    # Get client statistics
    def stats
      {
        name: @name,
        connected: connected?,
        config: sanitized_config,
        tools_count: connected? ? list_tools.length : 0
      }
    end

    # Get authentication configuration (for debugging)
    def auth_info
      return { enabled: false } unless @config[:auth][:enabled]

      {
        enabled: true,
        configured_fields: @config[:auth][:config].keys,
        env_mapping: @config[:auth][:env_mapping]
      }
    end

    protected

    # Post-initialization setup - override in subclasses if needed
    def post_initialize_setup
      # Override in subclasses for additional setup after config is set
    end

    # Default configuration - override in subclasses
    def default_config
      {
        transport: 'stdio',
        test_on_connect: false,
        auto_setup: false,
        auth: {
          enabled: false,
          config: {},
          env_mapping: {}
        },
        environment: {}
      }
    end

    # Validate configuration - override in subclasses
    def validate_config!
      Rails.logger.debug { "[Mcp::#{self.class.name}] Validating configuration with command: #{@config[:command]}" }
      raise ConfigurationError, 'Command is required' if @config[:command].blank?
    end

    # Create the actual MCP client - override in subclasses
    def create_client
      Rails.logger.debug { "[Mcp::#{self.class.name}] Creating client with config: #{@config.inspect}" }
      case @config[:transport]
      when 'stdio'
        create_stdio_client
      else
        raise ConfigurationError, "Unsupported transport: #{@config[:transport]}"
      end
    end

    # Create stdio client
    def create_stdio_client
      command = @config[:command]
      raise ConfigurationError, 'Command required for stdio transport' if command.blank?

      Rails.logger.debug { "[Mcp::#{self.class.name}] Creating stdio client with command: #{command.join(' ')}" }

      # Prepare environment variables if specified
      env_vars = @config[:environment] || {}
      final_command = command

      if env_vars.any?
        Rails.logger.debug { "[Mcp::#{self.class.name}] Setting environment variables: #{env_vars.keys.join(', ')}" }
        Rails.logger.debug do
          "[Mcp::#{self.class.name}] Environment values: #{env_vars.transform_values do |v|
            v.to_s.length > 10 ? "#{v.to_s[0..8]}..." : v.to_s
          end}"
        end

        # Create a wrapper script to ensure environment variables are passed correctly
        wrapper_script = create_env_wrapper_script(command, env_vars)
        if wrapper_script
          final_command = ['sh', wrapper_script]
          Rails.logger.debug { "[Mcp::#{self.class.name}] Using wrapper script: #{wrapper_script}" }
        else
          # Fallback: Set in current process
          env_vars.each do |key, value|
            if value
              ENV[key.to_s] = value.to_s
              Rails.logger.debug { "[Mcp::#{self.class.name}] Set ENV['#{key}'] = '#{value.to_s[0..8]}...#{value.to_s[-3..]}'" }
            end
          end
        end
      else
        Rails.logger.debug { "[Mcp::#{self.class.name}] No environment variables to set" }
      end

      Rails.logger.debug { "[Mcp::#{self.class.name}] Initializing MCP client..." }

      MCPClient.create_client(
        mcp_server_configs: [
          MCPClient.stdio_config(
            command: final_command,
            name: @name
          )
        ]
      )
    end

    # Create a temporary wrapper script to ensure environment variables are passed
    def create_env_wrapper_script(command, env_vars)
      return nil unless env_vars.any?

      begin
        script_content = "#!/bin/bash\n"
        env_vars.each { |key, value| script_content += "export #{key}='#{value}'\n" }
        script_content += "exec #{command.join(' ')}\n"

        script_path = "/tmp/mcp_wrapper_#{@name}_#{Process.pid}.sh"
        File.write(script_path, script_content)
        File.chmod(0o755, script_path)

        @wrapper_script = script_path
        Rails.logger.debug { "[Mcp::#{self.class.name}] Created wrapper script: #{script_path}" }
        script_path
      rescue StandardError => e
        Rails.logger.warn("[Mcp::#{self.class.name}] Failed to create wrapper script: #{e.message}")
        nil
      end
    end

    # Clean up wrapper script
    def cleanup_wrapper_script
      return unless @wrapper_script && File.exist?(@wrapper_script)

      begin
        File.delete(@wrapper_script)
        Rails.logger.debug { "[Mcp::#{self.class.name}] Cleaned up wrapper script: #{@wrapper_script}" }
      rescue StandardError => e
        Rails.logger.warn("[Mcp::#{self.class.name}] Failed to cleanup wrapper script: #{e.message}")
      ensure
        @wrapper_script = nil
      end
    end

    # Test connection after connecting
    def test_connection
      tools = list_tools
      Rails.logger.debug { "[Mcp::#{self.class.name}] Connection test successful. Found #{tools.length} tools" }
    rescue StandardError => e
      Rails.logger.warn("[Mcp::#{self.class.name}] Connection test failed: #{e.message}")
    end

    private

    def ensure_connected!
      return if connected?

      raise ConnectionError, "Not connected to #{@name}. Call connect! first."
    end

    # Sanitize configuration for logging (remove sensitive data)
    def sanitized_config
      config = @config.dup

      # Remove sensitive auth data
      if config[:auth] && config[:auth][:config]
        config[:auth] = config[:auth].dup
        config[:auth][:config] = config[:auth][:config].transform_values { |_| '[REDACTED]' }
      end

      config
    end
  end
end