require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::ToolCatalogInstallations', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:pack) do
    Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example')
    ).compile
  end
  let(:registry) { instance_double(Captain::ToolCatalog::ProviderPackRegistry, all: [pack], find: pack) }
  let(:request_params) do
    {
      installation: {
        provider_key: 'example',
        templates: [
          {
            template_key: 'get_current_customer',
            template_version: '1.0.0',
            configuration: {}
          }
        ]
      }
    }
  end

  before do
    account.enable_features!('captain_tool_catalog')
    allow(Chatwoot).to receive(:encryption_configured?).and_return(true)
    allow(Captain::ToolCatalog::ProviderPackRegistry).to receive(:default).and_return(registry)
  end

  describe 'POST /api/v1/accounts/:account_id/captain/tool_catalog/installations' do
    it 'installs selected snapshots for an administrator' do
      create(
        :integrations_hook,
        account: account,
        app_id: 'example',
        access_token: 'provider-secret',
        settings: { scope: 'customers:read', refresh_token: 'legacy-secret' }
      )

      post installations_path, params: request_params, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:created)
      expect(json_response.dig(:payload, :status)).to eq('completed')
      expect(json_response.dig(:payload, :resulting_tool_ids)).to contain_exactly(account.captain_custom_tools.catalog.sole.id)
      expect(response.body).not_to include('provider-secret', 'legacy-secret')
    end

    it 'returns a resumable state and missing scopes when connection is required' do
      post installations_path, params: request_params, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:created)
      expect(json_response.dig(:payload, :status)).to eq('awaiting_connection')
      expect(json_response.dig(:payload, :connection)).to eq(
        connected: false,
        status: 'disconnected',
        missing_scopes: ['customers:read']
      )
    end

    it 'rejects stale selections with a stable sanitized error code' do
      request_params.dig(:installation, :templates, 0)[:template_version] = '0.9.0'

      post installations_path, params: request_params, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to eq(error: { code: 'template_version_changed' })
      expect(account.captain_tool_catalog_installations).to be_empty
    end

    it 'rejects non-administrators' do
      post installations_path, params: request_params, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'GET /api/v1/accounts/:account_id/captain/tool_catalog/installations/:id' do
    it 'returns safe resumable state without OAuth nonce material' do
      installation = create(
        :captain_tool_catalog_installation,
        account: account,
        initiated_by: admin,
        oauth_nonce_digest: 'a' * 64
      )

      get "#{installations_path}/#{installation.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response.dig(:payload, :id)).to eq(installation.id)
      expect(json_response.dig(:payload, :selected_templates)).to eq(installation.selected_templates.map(&:deep_symbolize_keys))
      expect(response.body).not_to include('a' * 64, 'oauth_nonce_digest', 'integration_hook_id')
    end

    it 'does not return another account session' do
      other_installation = create(:captain_tool_catalog_installation)

      get "#{installations_path}/#{other_installation.id}", headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  def installations_path
    "/api/v1/accounts/#{account.id}/captain/tool_catalog/installations"
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end
