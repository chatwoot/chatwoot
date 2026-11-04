require 'rails_helper'

RSpec.describe 'Captain::McpCallbacks', type: :request do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:server) do
    Captain::McpServer.create!(account: account, assistant: assistant, name: 'Invoicely', url: 'https://mcp.example.com/mcp', auth_type: 'oauth')
  end
  let(:servers_page) do
    "/app/accounts/#{account.id}/captain/#{assistant.id}/tools/mcp?mcp_server_id=#{server.id}"
  end
  # The params each sign-in was finished with
  let(:authorized) { [] }

  before do
    account.enable_features!(Captain::McpServer::FEATURE_FLAG)
    server.remember_oauth_state('state-123')
  end

  def finish_sign_in(state: 'state-123', &authorize)
    allow(Captain::Mcp::Connection).to receive(:new).and_wrap_original do |original, signed_in_server|
      original.call(signed_in_server).tap { |connection| allow(connection).to receive(:authorize, &authorize) }
    end
    get '/captain/mcp/callback', params: { code: 'code-1', state: state, iss: 'https://auth.example.com', extra: 'dropped' }
  end

  it 'finishes the sign-in, marks the server active and returns to its page' do
    finish_sign_in { |params| authorized << params }

    expect(response).to redirect_to("#{servers_page}&sign_in=success")
    expect(authorized).to eq([{ 'code' => 'code-1', 'state' => 'state-123', 'iss' => 'https://auth.example.com' }])
    expect(server.reload).to be_active
  end

  it 'reports a failed sign-in and records why' do
    finish_sign_in { raise RubyLLM::MCP::Error, 'Authorization failed: access_denied' }

    expect(response).to redirect_to("#{servers_page}&sign_in=failed")
    expect(server.reload).to have_attributes(status: 'error', last_error: 'Authorization failed: access_denied')
  end

  it 'uses a state only once' do
    finish_sign_in { |params| authorized << params }
    finish_sign_in { |params| authorized << params }

    expect(response).to redirect_to('/app')
    expect(authorized.size).to eq(1)
  end

  it 'sends an unknown state to the app without signing in' do
    finish_sign_in(state: 'unknown') { |params| authorized << params }

    expect(response).to redirect_to('/app')
    expect(authorized).to be_empty
  end

  it 'does not finish a sign-in once the account loses MCP servers' do
    account.disable_features!(Captain::McpServer::FEATURE_FLAG)

    finish_sign_in { |params| authorized << params }

    expect(response).to redirect_to('/app')
    expect(authorized).to be_empty
  end
end
