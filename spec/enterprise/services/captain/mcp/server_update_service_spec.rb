require 'rails_helper'

RSpec.describe Captain::Mcp::ServerUpdateService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:server) do
    Captain::McpServer.create!(account: account, assistant: assistant, name: 'Invoicely', url: 'https://mcp.example.com/mcp',
                               auth_type: 'token', auth_config: { 'token' => 'old' })
  end
  let(:schema) { { 'type' => 'object', 'properties' => { 'email' => { 'type' => 'string' } } } }
  let(:live_tools) do
    %w[get_customer list_invoices].map { |name| { 'name' => name, 'description' => 'Look up', 'input_schema' => schema, 'read_only' => true } }
  end
  # The token each listing of the live tools was sent with
  let(:listings) { [] }

  before do
    allow(Captain::Mcp::Connection).to receive(:new).and_wrap_original do |original, listed_server|
      original.call(listed_server).tap do |connection|
        allow(connection).to receive(:tool_definitions) do
          listings << listed_server.auth_config['token']
          live_tools
        end
      end
    end
  end

  def update(attributes, tools)
    described_class.new(Captain::McpServer.find(server.id), attributes, tools).perform
  end

  it 'approves new tools, keeps approved ones and removes the ones left out' do
    update({}, [{ 'name' => 'get_customer' }, { 'name' => 'list_invoices' }])
    update({}, [{ 'name' => 'list_invoices', 'enabled' => false }])

    expect(server.tools.reload.map { |tool| [tool.name, tool.enabled] }).to eq([['list_invoices', false]])
  end

  it 'lists the live tools only when the selection adds a tool' do
    update({}, [{ 'name' => 'get_customer' }])
    update({}, [{ 'name' => 'get_customer', 'enabled' => false }])

    expect(listings.size).to eq(1)
  end

  it 'leaves the tools alone when the request sends none' do
    update({}, [{ 'name' => 'get_customer' }])

    update({ 'name' => 'Renamed' }, nil)

    expect(server.reload.name).to eq('Renamed')
    expect(server.tools.map(&:name)).to eq(['get_customer'])
  end

  it 'rejects an invalid edit before it calls the server' do
    expect { update({ 'auth_header' => 'Content-Type' }, [{ 'name' => 'get_customer' }]) }.to raise_error(ActiveRecord::RecordInvalid)

    expect(listings).to be_empty
    expect(server.reload.auth_header).to be_nil
  end

  it 'lists the tools with a new token and clears the error the old one caused' do
    server.record_failure(RubyLLM::UnauthorizedError.new)

    update({ 'auth_config' => { 'token' => 'new' } }, [{ 'name' => 'get_customer' }])

    expect(listings).to eq(['new'])
    expect(server.reload).to have_attributes(status: 'active', last_error: nil)
    expect(server.auth_config['token']).to eq('new')
  end

  it 'keeps the failed status when the server fails, and saves nothing' do
    allow(Captain::Mcp::Connection).to receive(:new).and_wrap_original do |original, listed_server|
      original.call(listed_server).tap { |connection| allow(connection).to receive(:tool_definitions).and_raise(Faraday::TimeoutError, 'timed out') }
    end

    expect { update({ 'name' => 'Renamed' }, [{ 'name' => 'get_customer' }]) }.to raise_error(Faraday::TimeoutError)

    expect(server.reload).to have_attributes(status: 'error', last_error: 'timed out', name: 'Invoicely')
    expect(server.tools).to be_empty
  end

  it 'saves neither the edit nor the tools when a selected tool is missing on the server' do
    expect { update({ 'name' => 'Renamed' }, [{ 'name' => 'delete_everything' }]) }
      .to raise_error(ActiveRecord::RecordInvalid, /The server no longer offers delete_everything/)

    expect(server.reload.name).to eq('Invoicely')
  end

  it 'rejects a selection with the wrong shape' do
    expect { update({}, [{ 'name' => 'get_customer', 'settings' => 'yes' }]) }
      .to raise_error(ActiveRecord::RecordInvalid, /its settings must be an object/)
    expect { update({}, ['get_customer']) }.to raise_error(ActiveRecord::RecordInvalid, /Each tool selection must be an object/)
  end

  it 'rejects the same tool twice' do
    expect { update({}, [{ 'name' => 'get_customer' }, { 'name' => 'get_customer' }]) }
      .to raise_error(ActiveRecord::RecordInvalid, /cannot list the same tool twice/)
  end
end
