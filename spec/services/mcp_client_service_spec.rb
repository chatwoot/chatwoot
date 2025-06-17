# frozen_string_literal: true

require 'rails_helper'

RSpec.describe McpClientService, type: :service do
  let(:service) { described_class.instance }

  before do
    # Reset singleton state between tests
    described_class.instance_variable_set(:@singleton__instance__, nil)

    # Mock environment variables
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('HOME').and_return('/tmp')
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('MCP_SERVER_ID').and_return('test-mcp-server')

    # Mock file existence checks
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/tmp/.mcp/test-mcp-server').and_return(true)

    # Prevent actual MCP client creation during tests
    allow(service).to receive(:setup_clients)
    allow(service).to receive(:setup_mcp_server_if_needed)
  end

  describe '#initialize' do
    it 'initializes with empty clients and stats' do
      expect(service.clients).to be_a(Hash)
      expect(service.connection_stats).to be_a(Hash)
    end
  end

  describe '#client_for' do
    context 'when requesting mintlify client' do
      let(:mock_client) { instance_double(MCPClient) }

      before do
        # Override the stubbed setup_clients for this test
        allow(service).to receive(:setup_clients)
        allow(MCPClient).to receive(:create_client).and_return(mock_client)
        allow(mock_client).to receive(:list_tools).and_return([])
      end

      it 'creates and returns a mintlify client' do
        client = service.client_for('mintlify')
        expect(client).to eq(mock_client)
      end
    end

    context 'when requesting unknown server' do
      it 'raises ConfigurationError' do
        expect { service.client_for('unknown') }.to raise_error(McpClientService::ConfigurationError)
      end
    end
  end

  describe '#call_tool' do
    let(:mock_client) { instance_double(MCPClient) }

    before do
      allow(service).to receive(:client_for).with('mintlify').and_return(mock_client)
    end

    context 'with valid parameters' do
      it 'calls tool successfully and records metrics' do
        expect(mock_client).to receive(:call_tool).with('search', { query: 'test' }).and_return('result')

        result = service.call_tool('mintlify', 'search', { query: 'test' })

        expect(result).to eq('result')
        expect(service.connection_stats['mintlify'][:successful_calls]).to eq(1)
      end
    end

    context 'with invalid parameters' do
      it 'raises ArgumentError for blank server_name' do
        expect { service.call_tool('', 'search', {}) }.to raise_error(ArgumentError, 'server_name cannot be blank')
      end

      it 'raises ArgumentError for blank tool_name' do
        expect { service.call_tool('mintlify', '', {}) }.to raise_error(ArgumentError, 'tool_name cannot be blank')
      end

      it 'raises ArgumentError for non-hash arguments' do
        expect { service.call_tool('mintlify', 'search', 'not_hash') }.to raise_error(ArgumentError, 'arguments must be a Hash')
      end
    end

    context 'when tool call fails' do
      it 'handles errors gracefully' do
        allow(mock_client).to receive(:call_tool).and_raise(StandardError.new('Connection failed'))

        result = service.call_tool('mintlify', 'search', { query: 'test' })
        expect(result).to be_a(String)
        expect(result).to include('could not search')
      end
    end
  end

  describe '#list_tools' do
    let(:mock_client) { instance_double(MCPClient) }
    let(:mock_tools) { [{ 'name' => 'search', 'description' => 'Search docs' }] }

    before do
      allow(service).to receive(:client_for).with('mintlify').and_return(mock_client)
    end

    it 'returns tools from client' do
      expect(mock_client).to receive(:list_tools).and_return(mock_tools)

      tools = service.list_tools('mintlify')
      expect(tools).to eq(mock_tools)
    end

    it 'returns empty array on error' do
      expect(mock_client).to receive(:list_tools).and_raise(StandardError)

      tools = service.list_tools('mintlify')
      expect(tools).to eq([])
    end
  end

  describe '#all_tools' do
    it 'returns tools from all servers' do
      allow(service).to receive(:list_tools).with('mintlify').and_return([{ 'name' => 'search' }])
      service.instance_variable_set(:@clients, { 'mintlify' => instance_double(MCPClient) })

      tools = service.all_tools
      expect(tools).to have_key('mintlify')
      expect(tools['mintlify']).to eq([{ 'name' => 'search' }])
    end
  end

  describe '#stats' do
    it 'returns service statistics' do
      stats = service.stats

      expect(stats).to have_key(:clients)
      expect(stats).to have_key(:connection_stats)
    end
  end

  describe '#reconnect_all!' do
    let(:mock_client) { instance_double(MCPClient, close: nil) }

    before do
      service.instance_variable_set(:@clients, { 'mintlify' => mock_client })
    end

    it 'clears clients and reconnects' do
      service.reconnect_all!

      expect(service.clients).to be_empty
    end
  end

  describe 'error handling' do
    context 'when MCP server directory does not exist' do
      before do
        allow(File).to receive(:exist?).with('/tmp/.mcp/test-mcp-server').and_return(false)
        # Don't stub setup methods for this test to test the actual error handling
        allow(service).to receive(:setup_clients).and_call_original
        allow(service).to receive(:setup_mcp_server_if_needed).and_call_original
      end

      it 'raises ConfigurationError in production' do
        mock_env = instance_double(Rails.env, production?: true, development?: false)
        allow(Rails).to receive(:env).and_return(mock_env)

        expect { described_class.instance }.to raise_error(McpClientService::ConfigurationError)
      end
    end

    context 'when MCP_SERVER_ID environment variable is not set' do
      before do
        # Remove the MCP_SERVER_ID mock to test the error handling
        allow(ENV).to receive(:fetch).with('MCP_SERVER_ID').and_raise(KeyError)
        allow(service).to receive(:setup_clients).and_call_original
      end

      it 'raises ConfigurationError with helpful message' do
        expect { described_class.instance }.to raise_error(
          McpClientService::ConfigurationError,
          /MCP_SERVER_ID environment variable is required/
        )
      end
    end

    context 'when using custom MCP_SERVER_ID' do
      before do
        # Override the environment variable for this test
        allow(ENV).to receive(:fetch).with('MCP_SERVER_ID').and_return('custom-server-id')
        allow(File).to receive(:exist?).with('/tmp/.mcp/custom-server-id').and_return(false)
        allow(service).to receive(:setup_clients).and_call_original
        allow(service).to receive(:setup_mcp_server_if_needed).and_call_original
      end

      it 'uses the custom server id from environment variable' do
        mock_env = instance_double(Rails.env, production?: true, development?: false)
        allow(Rails).to receive(:env).and_return(mock_env)

        expect { described_class.instance }.to raise_error(McpClientService::ConfigurationError, /custom-server-id/)
      end
    end
  end
end