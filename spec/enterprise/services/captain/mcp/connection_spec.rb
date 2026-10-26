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
      expect(connection.server_version).to eq('1.2')
    end
  end
end
