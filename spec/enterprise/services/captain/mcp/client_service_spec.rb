require 'rails_helper'

# Mock interfaces for external MCP library
module MockMcpClient
  def list_tools(**_options); end
  def call_tool(_name, _args = {}); end
  def cleanup; end
end

module MockMcpTool
  def name; end
  def description; end
  def schema; end
  def output_schema; end
  def annotations; end
end

RSpec.describe Captain::Mcp::ClientService do
  let(:account) { create(:account) }
  let(:mcp_server) { create(:captain_mcp_server, account: account) }
  let(:service) { described_class.new(mcp_server) }

  describe '#connect' do
    context 'when connection succeeds' do
      before do
        allow(Resolv).to receive(:getaddress).and_return('203.0.113.1')
        allow(MCPClient).to receive(:connect).and_return(instance_double(MockMcpClient, list_tools: []))
      end

      it 'returns success result' do
        result = service.connect
        expect(result).to be_success
      end

      it 'updates server status to connected' do
        service.connect
        expect(mcp_server.reload.status).to eq('connected')
      end

      it 'sets last_connected_at timestamp' do
        freeze_time do
          service.connect
          expect(mcp_server.reload.last_connected_at).to eq(Time.current)
        end
      end
    end

    context 'when hostname resolves to private IP' do
      before do
        allow(Resolv).to receive(:getaddress).and_return('192.168.1.1')
      end

      it 'returns failure result' do
        result = service.connect
        expect(result).not_to be_success
        expect(result.error).to include('private IP')
      end

      it 'marks server as error' do
        service.connect
        expect(mcp_server.reload.status).to eq('error')
      end
    end

    context 'when hostname resolves to localhost' do
      before do
        allow(Resolv).to receive(:getaddress).and_return('127.0.0.1')
      end

      it 'returns failure result' do
        result = service.connect
        expect(result).not_to be_success
      end
    end

    context 'when DNS resolution fails' do
      before do
        allow(Resolv).to receive(:getaddress).and_raise(Resolv::ResolvError.new('DNS failed'))
      end

      it 'returns failure result with DNS error' do
        result = service.connect
        expect(result).not_to be_success
        expect(result.error).to include('DNS')
      end
    end

    context 'when MCP client raises error' do
      before do
        allow(Resolv).to receive(:getaddress).and_return('203.0.113.1')
        allow(MCPClient).to receive(:connect).and_raise(MCPClient::Errors::ConnectionError.new('Connection refused'))
      end

      it 'returns failure result' do
        result = service.connect
        expect(result).not_to be_success
        expect(result.error).to include('Connection refused')
      end

      it 'marks server as error with message' do
        service.connect
        expect(mcp_server.reload.status).to eq('error')
        expect(mcp_server.last_error).to include('Connection refused')
      end
    end
  end

  describe '#disconnect' do
    let(:mock_client) { instance_double(MockMcpClient, cleanup: nil, list_tools: []) }

    before do
      allow(Resolv).to receive(:getaddress).and_return('203.0.113.1')
      allow(MCPClient).to receive(:connect).and_return(mock_client)
      service.connect
    end

    it 'cleans up the client' do
      expect(mock_client).to receive(:cleanup)
      service.disconnect
    end

    it 'marks server as disconnected' do
      service.disconnect
      expect(mcp_server.reload.status).to eq('disconnected')
    end
  end

  describe '#list_tools' do
    let(:mock_tool) do
      instance_double(MockMcpTool,
                      name: 'search_docs',
                      description: 'Search documentation',
                      schema: { 'type' => 'object', 'properties' => { 'query' => { 'type' => 'string' } } },
                      output_schema: nil,
                      annotations: nil)
    end
    let(:mock_client) { instance_double(MockMcpClient, list_tools: [mock_tool]) }

    before do
      allow(Resolv).to receive(:getaddress).and_return('203.0.113.1')
      allow(MCPClient).to receive(:connect).and_return(mock_client)
    end

    it 'returns serialized tools' do
      tools = service.list_tools

      expect(tools.length).to eq(1)
      expect(tools.first['name']).to eq('search_docs')
      expect(tools.first['description']).to eq('Search documentation')
      expect(tools.first['inputSchema']).to be_present
    end

    context 'when connection error occurs' do
      before do
        allow(mock_client).to receive(:list_tools).and_raise(MCPClient::Errors::ConnectionError.new('Lost connection'))
      end

      it 'raises ConnectionError' do
        service.connect
        expect { service.list_tools }.to raise_error(Captain::Mcp::ConnectionError, 'Lost connection')
      end
    end
  end

  describe '#call_tool' do
    let(:mock_client) { instance_double(MockMcpClient, list_tools: []) }

    before do
      allow(Resolv).to receive(:getaddress).and_return('203.0.113.1')
      allow(MCPClient).to receive(:connect).and_return(mock_client)
    end

    context 'when tool returns text content' do
      before do
        allow(mock_client).to receive(:call_tool).and_return({
                                                               'content' => [{ 'type' => 'text', 'text' => 'Search results here' }]
                                                             })
      end

      it 'formats and returns the text' do
        result = service.call_tool('search_docs', { query: 'test' })
        expect(result).to eq('Search results here')
      end
    end

    context 'when tool returns string directly' do
      before do
        allow(mock_client).to receive(:call_tool).and_return('Direct response')
      end

      it 'returns the string as-is' do
        result = service.call_tool('search_docs', {})
        expect(result).to eq('Direct response')
      end
    end

    context 'when tool returns image content' do
      before do
        allow(mock_client).to receive(:call_tool).and_return({
                                                               'content' => [{ 'type' => 'image', 'mimeType' => 'image/png' }]
                                                             })
      end

      it 'formats image as placeholder text' do
        result = service.call_tool('get_image', {})
        expect(result).to eq('[Image: image/png]')
      end
    end

    context 'when tool execution fails' do
      before do
        allow(mock_client).to receive(:call_tool).and_raise(MCPClient::Errors::ToolCallError.new('Tool failed'))
      end

      it 'raises ToolExecutionError' do
        service.connect
        expect { service.call_tool('failing_tool', {}) }.to raise_error(Captain::Mcp::ToolExecutionError, 'Tool failed')
      end
    end
  end

  describe 'SSRF protection' do
    describe 'private IP ranges' do
      let(:private_ips) do
        [
          '127.0.0.1',      # Loopback
          '10.0.0.1',       # Private class A
          '172.16.0.1',     # Private class B
          '192.168.1.1',    # Private class C
          '169.254.1.1',    # Link-local
          '0.0.0.1'         # Current network
        ]
      end

      it 'blocks all private IP ranges' do
        private_ips.each do |ip|
          allow(Resolv).to receive(:getaddress).and_return(ip)

          result = service.connect
          expect(result).not_to be_success, "Expected #{ip} to be blocked"
        end
      end
    end

    it 'allows public IP addresses' do
      allow(Resolv).to receive(:getaddress).and_return('203.0.113.1')
      allow(MCPClient).to receive(:connect).and_return(instance_double(MockMcpClient, list_tools: []))

      result = service.connect
      expect(result).to be_success
    end
  end
end
