require 'rails_helper'

RSpec.describe Captain::Mcp::ToolChangeCheckJob do
  let(:definition) { { 'name' => 'list_invoices', 'description' => 'List invoices', 'input_schema' => {}, 'read_only' => true } }
  let(:connection) { instance_double(Captain::Mcp::Connection, recent_tool_definitions: [definition]) }

  def create_server_with_tool(account)
    assistant = create(:captain_assistant, account: account)
    server = Captain::McpServer.create!(account: account, assistant: assistant, name: 'Invoicely', url: 'https://mcp.example.com/mcp')
    server.sync_tools({ 'list_invoices' => {} }, { 'list_invoices' => definition })
    server
  end

  before do
    allow(Captain::Mcp::Connection).to receive(:new).and_return(connection)
  end

  it 'checks the tools of a server whose account has MCP servers turned on' do
    account = create(:account)
    account.enable_features!(Captain::McpServer::FEATURE_FLAG)
    server = create_server_with_tool(account)

    described_class.perform_now

    expect(Captain::Mcp::Connection).to have_received(:new).with(server)
  end

  it 'skips a server whose account has MCP servers turned off' do
    create_server_with_tool(create(:account))

    described_class.perform_now

    expect(Captain::Mcp::Connection).not_to have_received(:new)
  end
end
