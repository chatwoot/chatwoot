require 'rails_helper'

RSpec.describe Captain::Mcp::Connection do
  let(:server) { Captain::McpServer.new(id: 1, url: 'https://mcp.example.com/mcp', auth_type: 'none') }
  let(:connection) { described_class.new(server) }

  # RubyLLM keeps the server info private, so a gem update that renames it fails here
  describe '#server_name' do
    it 'reads the name the server reported when it connected' do
      client = instance_double(RubyLLM::MCP::Client, server: { 'serverInfo' => { 'name' => 'Example', 'version' => '1.2' } })
      allow(connection.mcp).to receive(:client).and_return(client)

      expect(connection.server_name).to eq('Example')
    end
  end

  describe '#tool_definitions' do
    it 'reports a tool list the MCP client cannot read as an invalid response, without sending it to Sentry' do
      allow(connection.mcp).to receive(:tools).and_raise(NoMethodError, "undefined method 'fetch' for an instance of String")
      allow(ChatwootExceptionTracker).to receive(:new)

      expect { connection.tool_definitions }.to raise_error(described_class::InvalidResponse, /could not read \(NoMethodError\)/)
      expect(ChatwootExceptionTracker).not_to have_received(:new)
    end
  end

  describe 'response size' do
    let(:fake) { FakeMcpServer.new }
    let(:limit) { Captain::Mcp::SafeFaradayAdapter::MAX_RESPONSE_BYTES }

    before do
      allow(SsrfFilter::DEFAULT_RESOLVER).to receive(:call).and_return([IPAddr.new('93.184.216.34')])
      stub_request(:any, server.url).to_rack(fake)
      fake.tools = [{ name: 'get_customer', description: 'Find a customer', inputSchema: { type: 'object', properties: {} } }]
    end

    it 'stops reading a tool result that is larger than the limit' do
      fake.call_text = 'a' * (limit + 1)

      expect { connection.call('get_customer', {}) }.to raise_error(Captain::Mcp::SafeFaradayAdapter::ResponseTooLarge)
    end

    it 'stops reading a tool list that is larger than the limit' do
      fake.tools = [fake.tools.first.merge(description: 'a' * (limit + 1))]

      expect { connection.tool_definitions }.to raise_error(Captain::Mcp::SafeFaradayAdapter::ResponseTooLarge)
    end

    it 'reads a tool result within the limit' do
      fake.call_text = 'a' * 1000

      expect(connection.call('get_customer', {}).text).to eq('a' * 1000)
    end
  end
end
