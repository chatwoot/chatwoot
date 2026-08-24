require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::ToolCatalog', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:compiled_pack) do
    Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example')
    ).compile
  end
  let(:registry) { instance_double(Captain::ToolCatalog::ProviderPackRegistry, all: [compiled_pack]) }

  before do
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
    allow(registry).to receive(:find) do |provider_key|
      raise ActiveRecord::RecordNotFound unless provider_key == 'example'

      compiled_pack
    end
    allow(Captain::ToolCatalog::ProviderPackRegistry).to receive(:default).and_return(registry)
  end

  describe 'GET /api/v1/accounts/:account_id/captain/tool_catalog' do
    it 'requires authentication' do
      account.enable_features!('captain_tool_catalog')

      get "/api/v1/accounts/#{account.id}/captain/tool_catalog"

      expect(response).to have_http_status(:unauthorized)
    end

    it 'is restricted to account administrators' do
      account.enable_features!('captain_tool_catalog')

      get "/api/v1/accounts/#{account.id}/captain/tool_catalog", headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'requires the private catalog feature' do
      get "/api/v1/accounts/#{account.id}/captain/tool_catalog", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns the account-scoped provider catalog and capacity' do
      account.enable_features!('captain_tool_catalog')
      create(:captain_custom_tool, account: account)

      get "/api/v1/accounts/#{account.id}/captain/tool_catalog", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response.dig(:payload, 0, :key)).to eq('example')
      expect(json_response.dig(:meta, :capacity)).to eq(used: 1, limit: 50)
    end
  end

  describe 'GET /api/v1/accounts/:account_id/captain/tool_catalog/:provider_key' do
    before { account.enable_features!('captain_tool_catalog') }

    it 'returns provider categories and templates' do
      get "/api/v1/accounts/#{account.id}/captain/tool_catalog/example", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response.dig(:payload, :key)).to eq('example')
      expect(json_response.dig(:payload, :categories, 0, :templates, 0, :key)).to eq('get_current_customer')
    end

    it 'returns not found for a provider outside the registry' do
      get "/api/v1/accounts/#{account.id}/captain/tool_catalog/unknown", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/captain/tool_catalog/:provider_key/update' do
    before { account.enable_features!('captain_tool_catalog') }

    it 'updates an explicitly selected installed snapshot' do
      create(:integrations_hook, account: account, app_id: 'example', settings: { scope: 'customers:read' })
      tool = create(
        :captain_custom_tool,
        :catalog,
        account: account,
        provider_key: 'example',
        template_key: 'get_current_customer',
        template_version: '0.9.0'
      )

      post "/api/v1/accounts/#{account.id}/captain/tool_catalog/example/update",
           params: {
             update: {
               templates: [{ template_key: 'get_current_customer', template_version: '1.0.0', configuration: {} }]
             }
           },
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:created)
      expect(json_response.dig(:payload, :workflow_kind)).to eq('update')
      expect(json_response.dig(:payload, :status)).to eq('completed')
      expect(tool.reload.template_version).to eq('1.0.0')
    end
  end

  describe 'POST /api/v1/accounts/:account_id/captain/tool_catalog/:provider_key/reconnect' do
    before { account.enable_features!('captain_tool_catalog') }

    it 'creates a resumable reconnect workflow when the connection is absent' do
      snapshot = Captain::ToolCatalog::SnapshotBuilder.new(
        pack: compiled_pack,
        entry: { template: compiled_pack.fetch('templates').sole, configuration: {} },
        integration_hook: nil
      ).attributes
      create(:captain_custom_tool, account: account, **snapshot)

      post "/api/v1/accounts/#{account.id}/captain/tool_catalog/example/reconnect",
           headers: admin.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:created)
      expect(json_response.dig(:payload, :workflow_kind)).to eq('reconnect')
      expect(json_response.dig(:payload, :status)).to eq('awaiting_connection')
      expect(json_response.dig(:payload, :connection, :missing_scopes)).to eq(['customers:read'])
    end
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end
