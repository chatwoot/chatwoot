# frozen_string_literal: true

require_relative '../base_client'

module Mcp
  module Clients
    # Mintlify MCP Client
    # Handles connection to Mintlify documentation server
    class MintlifyClient < BaseClient
      DEFAULT_SERVER_ID = 'chatwoot-447c5a93'

      def initialize(config = {})
        super('mintlify', build_config(config))
      end

      # Quick connect method with auto-setup
      def self.connect_with_setup(config = {})
        client = new(config)
        client.setup_if_needed! if client.config[:auto_setup]
        client.connect!
        client
      end

      # Setup Mintlify MCP server if needed
      def setup_if_needed!
        return if server_installed?

        Rails.logger.info('[Mcp::Clients::MintlifyClient] Setting up Mintlify MCP server...')

        install_mcp_cli && add_mcp_server

        raise ConfigurationError, 'Failed to setup Mintlify MCP server automatically' unless server_installed?

        Rails.logger.info('[Mcp::Clients::MintlifyClient] Setup completed successfully')
      end

      # Check if server is properly installed
      def server_installed?
        !server_path.nil? && File.exist?(server_path)
      end

      # Get available capabilities
      def capabilities
        %w[documentation_search code_examples api_reference]
      end

      protected

      def default_config
        super.merge({
                      server_id: DEFAULT_SERVER_ID,
                      command: nil, # Will be built after config is set
                      auto_setup: true,
                      test_on_connect: true,
                      auth: {
                        enabled: false,
                        config: {},
                        env_mapping: {}
                      },
                      environment: {}
                    })
      end

      def post_initialize_setup
        # Find the actual server path and update config
        actual_server_path = find_server_path
        if actual_server_path
          @config[:command] = ['node', actual_server_path]
          @server_path = actual_server_path

          # Extract the actual server ID from the path for logging
          actual_server_id = File.dirname(actual_server_path).split('/').last
          Rails.logger.debug { "[Mcp::Clients::MintlifyClient] Using server at: #{actual_server_path} (ID: #{actual_server_id})" }
        else
          @config[:command] = build_command
        end
        super
      end

      def validate_config!
        # Check if the exact server is installed
        unless server_installed?
          if @config[:auto_setup]
            setup_if_needed!
          else
            available_servers = list_available_servers
            error_msg = "Mintlify MCP server '#{@config[:server_id]}' not found.\n"

            if available_servers.any?
              error_msg += "Available servers: #{available_servers.join(', ')}\n"
              error_msg += "Please use one of these server IDs or install '#{@config[:server_id]}'"
            else
              error_msg += "No MCP servers found. Run 'rake mcp:setup' to install servers."
            end

            raise ConfigurationError, error_msg
          end
        end

        super
      end

      private

      def build_config(user_config)
        # Build auth config first
        auth_config = build_auth_config(user_config[:auth] || {})

        base_config = {
          server_id: user_config[:server_id] || DEFAULT_SERVER_ID,
          auto_setup: user_config.fetch(:auto_setup, true),
          test_on_connect: user_config.fetch(:test_on_connect, true),
          auth: auth_config,
          environment: build_environment_config(user_config[:environment] || {}, auth_config)
        }
        base_config.merge(user_config.except(:auth, :environment))
      end

      def build_command
        ['node', server_path]
      end

      def server_path
        @server_path ||= find_server_path
      end

      def find_server_path
        home_dir = Dir.home || '/root'
        mcp_dir = "#{home_dir}/.mcp"

        return nil unless Dir.exist?(mcp_dir)

        # Only use the exact server ID specified - no fallback
        expected_path = "#{mcp_dir}/#{@config[:server_id]}/src/index.js"

        if File.exist?(expected_path)
          Rails.logger.debug { "[Mcp::Clients::MintlifyClient] Found exact server at: #{expected_path}" }
          return expected_path
        else
          Rails.logger.debug { "[Mcp::Clients::MintlifyClient] Server #{@config[:server_id]} not found at #{expected_path}" }
          return nil
        end
      end

      def install_mcp_cli
        Rails.logger.debug('[Mcp::Clients::MintlifyClient] Installing MCP CLI...')
        system('npm install -g @mintlify/mcp 2>/dev/null')
      end

      def add_mcp_server
        Rails.logger.debug { "[Mcp::Clients::MintlifyClient] Adding server #{@config[:server_id]}..." }

        # Run mcp add command for the server
        success = system("mcp add #{@config[:server_id]} 2>/dev/null")

        if success
          Rails.logger.debug { "[Mcp::Clients::MintlifyClient] Successfully added server #{@config[:server_id]}" }
        else
          Rails.logger.warn("[Mcp::Clients::MintlifyClient] Failed to add server #{@config[:server_id]}")
        end

        success
      end

      def list_available_servers
        home_dir = Dir.home || '/root'
        mcp_dir = "#{home_dir}/.mcp"

        return [] unless Dir.exist?(mcp_dir)

        # Find all directories with src/index.js
        available = []
        Dir.glob("#{mcp_dir}/*/src/index.js").each do |path|
          # Skip node_modules directories
          next if path.include?('/node_modules/')

          # Extract server directory name
          path_parts = path.split('/')
          mcp_index = path_parts.index('.mcp')
          if mcp_index && mcp_index < path_parts.length - 1
            server_id = path_parts[mcp_index + 1]
            available << server_id
          end
        end

        available
      end

      def build_auth_config(user_auth)
        # No default auth fields - completely configurable based on MCP server requirements
        # Users define whatever auth fields their specific MCP server needs

        # Get environment mapping from user config (no defaults)
        env_mapping = user_auth[:env_mapping] || {}

        # Build auth config from user config and environment variables
        auth_config = user_auth[:config] || {}

        # Auto-populate from environment variables if mapping is provided
        env_mapping.each do |config_key, env_var|
          auth_config[config_key] = ENV[env_var] if auth_config[config_key].nil? && ENV[env_var]
        end

        # Determine if auth is enabled
        enabled = user_auth.fetch(:enabled, auth_config.any? { |_, value| value.present? })

        {
          enabled: enabled,
          config: auth_config,
          env_mapping: env_mapping
        }
      end

      def build_environment_config(user_env, auth_config = nil)
        env_config = {}

        # Add authentication environment variables if configured
        if auth_config && auth_config[:enabled]
          auth_config[:env_mapping].each do |config_key, env_var|
            value = auth_config[:config][config_key]
            env_config[env_var] = value if value.present?
          end
        end

        env_config.merge(user_env)
      end
    end
  end
end