require 'rails_helper'

RSpec.describe Captain::ToolCatalog::CatalogQuery do
  subject(:query) { described_class.new(account: account, registry: registry) }

  let(:account) { create(:account) }
  let(:compiled_pack) do
    Captain::ToolCatalog::ProviderPackCompiler.new(
      pack_path: Rails.root.join('spec/fixtures/captain/tool_catalog/providers/example')
    ).compile
  end
  let(:registry) do
    instance_double(
      Captain::ToolCatalog::ProviderPackRegistry,
      all: [compiled_pack],
      find: compiled_pack
    )
  end

  before { account.enable_features!('captain_tool_catalog') }

  describe '#summaries' do
    it 'returns provider, connection, installation, availability, and capacity summaries' do
      create(
        :integrations_hook,
        account: account,
        app_id: 'example',
        access_token: 'catalog-access-secret',
        refresh_token: 'catalog-refresh-secret',
        settings: {
          scope: 'customers:read,customers:write',
          account_name: 'Acme',
          refresh_token: 'legacy-settings-secret'
        }
      )
      create(:captain_custom_tool, account: account)
      create(:captain_custom_tool, :catalog, account: account, provider_key: 'example', template_key: 'get_current_customer')

      response = query.summaries
      provider = response.dig(:payload, 0)

      expect(response.dig(:meta, :capacity)).to eq(used: 2, limit: 15)
      expect(provider).to include(
        'key' => 'example',
        'category_count' => 1,
        'available_template_count' => 1,
        'template_count' => 1,
        'installed_count' => 1,
        'update_count' => 0,
        'availability_counts' => { 'available' => 1 }
      )
      expect(provider.fetch('connection')).to eq(
        'connected' => true,
        'status' => 'enabled',
        'display_name' => 'Acme',
        'granted_scopes' => ['customers:read', 'customers:write']
      )
      expect(response.to_json).not_to include('catalog-access-secret', 'catalog-refresh-secret', 'legacy-settings-secret')
    end

    it 'does not expose credentials or data from another account' do
      other_account = create(:account)
      create(:integrations_hook, account: other_account, app_id: 'example', access_token: 'other-account-secret')
      create(:captain_custom_tool, :catalog, account: other_account, provider_key: 'example')

      response = query.summaries

      expect(response.dig(:payload, 0, 'installed_count')).to eq(0)
      expect(response.dig(:payload, 0, 'connection', 'status')).to eq('disconnected')
      expect(response.to_json).not_to include('other-account-secret')
    end
  end

  describe '#provider' do
    it 'groups public template metadata by category and adds installed state' do
      installed_tool = create(
        :captain_custom_tool,
        :catalog,
        account: account,
        provider_key: 'example',
        template_key: 'get_current_customer',
        template_version: '0.9.0'
      )

      response = query.provider('example')
      provider = response.fetch(:payload)
      template = provider.dig('categories', 0, 'templates', 0)

      expect(provider).to include(
        'key' => 'example',
        'authentication_strategy' => 'oauth',
        'installed_count' => 1
      )
      expect(template).to include(
        'key' => 'get_current_customer',
        'required_scopes' => ['customers:read'],
        'operation_keys' => ['find_customer'],
        'installed' => true,
        'installed_tool_id' => installed_tool.id,
        'installed_version' => '0.9.0',
        'installed_configuration' => {},
        'update_available' => true
      )
      expect(template.keys).not_to include('recipe', 'input_schema', 'output_schema')
    end
  end
end
