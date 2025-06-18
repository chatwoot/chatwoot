# frozen_string_literal: true

require_relative '../base_client'

module Mcp
  module Clients
    # Acme Mintlify MCP Client
    # Handles connection to specific Acme Mintlify server (acme-d0cb791b)
    # Requires api_access_token for authentication
    class AcmeMintlifyClient < BaseClient
      DEFAULT_SERVER_ID = 'acme-d0cb791b'

      def initialize(config = {})
        super('acme_mintlify', build_config(config))
      end

      def self.connect_with_setup(config = {})
        Rails.logger.info('[Mcp::Clients::AcmeMintlifyClient] Connecting to Acme Mintlify MCP server...')
        client = new(config)
        client.setup_if_needed! if client.config[:auto_setup]
        client.connect!
        client
      end

      def self.connect
        connect_with_setup({ auto_setup: true })
      end

      # Setup Acme Mintlify MCP server if needed
      def setup_if_needed!
        return if server_installed?

        Rails.logger.info('[Mcp::Clients::AcmeMintlifyClient] Setting up Acme Mintlify MCP server...')

        api_token = @config[:auth][:config]['api_access_token']

        Rails.logger.debug { "[Mcp::Clients::AcmeMintlifyClient] API token: #{api_token}" }
        Rails.logger.debug { "[Mcp::Clients::AcmeMintlifyClient] Config: #{@config.inspect}" }

        raise ConfigurationError, 'api_access_token is required for automatic setup' if api_token.blank?

        install_server_with_token(api_token)

        raise ConfigurationError, 'Failed to setup Acme Mintlify MCP server automatically' unless server_installed?

        Rails.logger.info('[Mcp::Clients::AcmeMintlifyClient] Setup completed successfully')
      end

      # Check if server is properly installed
      def server_installed?
        !server_path.nil? && File.exist?(server_path)
      end

      # Get available capabilities
      def capabilities
        %w[documentation_search api_access content_retrieval]
      end

      protected

      def default_config
        super.merge({
                      server_id: DEFAULT_SERVER_ID,
                      command: nil, # Will be built after config is set
                      auto_setup: true,
                      test_on_connect: true,
                      auth: {
                        enabled: false, # No runtime auth needed - API key only used during mcp add
                        config: {},
                        env_mapping: {}
                      },
                      environment: {}
                    })
      end

      def post_initialize_setup
        # Find the server and build command
        actual_server_path = find_server_path
        if actual_server_path
          @config[:command] = ['node', actual_server_path]
          @server_path = actual_server_path
          Rails.logger.debug { "[Mcp::Clients::AcmeMintlifyClient] Using server at: #{actual_server_path}" }
        else
          @config[:command] = build_fallback_command
        end

        super
      end

      def validate_config!
        # Check if the exact server is installed
        unless server_installed?
          if @config[:auto_setup]
            # For auto-setup, API token can be provided in config for installation
            api_token = @config.dig(:auth, :config, 'api_access_token')
            if api_token.blank?
              raise ConfigurationError,
                    'api_access_token is required for automatic setup of Acme server. ' \
                    'Use AcmeMintlifyClient.connect_with_setup for installation'
            end
            setup_if_needed!
          else
            raise ConfigurationError,
                  "Acme Mintlify MCP server '#{@config[:server_id]}' not found. " \
                  'Enable auto_setup for automatic installation'
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

      def build_auth_config(user_auth)
        # Auth config only used for installation (mcp add step)
        # Make sure to preserve any auth config passed in
        auth_config = {}

        # Copy auth config from user input
        auth_config = user_auth[:config].dup if user_auth && user_auth[:config]

        Rails.logger.debug { "[Mcp::Clients::AcmeMintlifyClient] Building auth config from: #{user_auth.inspect}" }
        Rails.logger.debug { "[Mcp::Clients::AcmeMintlifyClient] Extracted auth_config: #{auth_config.inspect}" }

        result = {
          enabled: false, # No runtime auth needed
          config: auth_config, # Store for installation if needed
          env_mapping: {}
        }

        Rails.logger.debug { "[Mcp::Clients::AcmeMintlifyClient] Final auth config: #{result.inspect}" }
        result
      end

      def build_environment_config(user_env, _auth_config = nil)
        # No runtime environment variables needed - server is configured during mcp add
        user_env
      end

      def server_path
        @server_path ||= find_server_path
      end

      def find_server_path
        home_dir = Dir.home || '/root'
        mcp_dir = "#{home_dir}/.mcp"

        return nil unless Dir.exist?(mcp_dir)

        # Only use the exact server ID specified
        expected_path = "#{mcp_dir}/#{@config[:server_id]}/src/index.js"

        if File.exist?(expected_path)
          Rails.logger.debug { "[Mcp::Clients::AcmeMintlifyClient] Found exact server at: #{expected_path}" }
          return expected_path
        else
          Rails.logger.debug { "[Mcp::Clients::AcmeMintlifyClient] Server #{@config[:server_id]} not found at #{expected_path}" }
          return nil
        end
      end

      def build_fallback_command
        ['node', "#{Dir.home || '/root'}/.mcp/#{@config[:server_id]}/src/index.js"]
      end

      def install_mcp_cli
        Rails.logger.debug('[Mcp::Clients::AcmeMintlifyClient] Installing MCP CLI...')
        system('npm install -g @mintlify/mcp 2>/dev/null')
      end

      def add_mcp_server
        Rails.logger.debug { "[Mcp::Clients::AcmeMintlifyClient] Adding server #{@config[:server_id]}..." }

        api_token = @config[:auth][:config]['api_access_token']
        if api_token.blank?
          Rails.logger.error('[Mcp::Clients::AcmeMintlifyClient] No API token provided for server installation')
          return false
        end

        # Use expect script to handle interactive installation
        install_with_expect(api_token)
      end

      def install_server_with_token(_api_token)
        Rails.logger.debug('[Mcp::Clients::AcmeMintlifyClient] Installing Acme Mintlify MCP server...')

        install_mcp_cli && add_mcp_server
      end

      def install_with_expect(api_token)
        Rails.logger.debug('[Mcp::Clients::AcmeMintlifyClient] Installing Acme Mintlify MCP server with expect...')
        # Use expect to handle the interactive prompt
        expect_script = <<~SCRIPT
          #!/usr/bin/expect -f
          spawn mcp add #{@config[:server_id]}
          expect "What is the API Key for \\"Chatwoot\\"?"
          send "#{api_token}\\r"
          expect eof
        SCRIPT
        script_path = "/tmp/mcp_install_#{@config[:server_id]}.exp"
        Rails.logger.debug { "[Mcp::Clients::AcmeMintlifyClient] Script path: #{script_path}" }
        File.write(script_path, expect_script)
        File.chmod(0o755, script_path)

        system(script_path)
        # File.delete(script_path) if File.exist?(script_path)
      end
    end
  end
end