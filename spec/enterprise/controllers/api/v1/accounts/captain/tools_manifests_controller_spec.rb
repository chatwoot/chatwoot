require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Captain::ToolsManifests', type: :request do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:revision) { 'a' * 40 }
  let(:source) { 'chatwoot/support-tools/shopify' }
  let(:manifest) do
    {
      'version' => '1.2.0',
      'kind' => 'captain_toolset',
      'name' => 'Shopify Support Tools',
      'description' => 'Look up Shopify orders.',
      'inputs' => { 'shop_domain' => { 'label' => 'Shopify store domain', 'placeholder' => 'acme.myshopify.com', 'required' => true } },
      'secrets' => { 'access_token' => { 'label' => 'Access token', 'type' => 'password', 'required' => true } },
      'tools' => [
        {
          'id' => 'get_order',
          'title' => 'Get Order',
          'description' => 'Retrieve an order by its ID.',
          'http_method' => 'GET',
          'endpoint_url' => 'https://${{ inputs.shop_domain }}/orders/{{ order_id }}.json',
          'auth_type' => 'bearer',
          'auth_config' => { 'token' => '${{ secrets.access_token }}' },
          'param_schema' => [{ 'name' => 'order_id', 'type' => 'string', 'description' => 'The order ID', 'required' => true }]
        }
      ]
    }
  end
  let(:configuration) { { inputs: { shop_domain: 'acme.myshopify.com' }, secrets: { access_token: 'shpat_secret' } } }
  let(:base_url) { "/api/v1/accounts/#{account.id}/captain/tools_manifest" }

  before do
    account.enable_features!('custom_tools')
    allow(Resolv).to receive(:getaddresses).and_return(['140.82.112.3'])
    stub_request(:get, 'https://api.github.com/repos/chatwoot/support-tools/commits/HEAD').to_return(status: 200, body: revision)
    stub_request(:get, "https://raw.githubusercontent.com/chatwoot/support-tools/#{revision}/shopify/toolset.yml")
      .to_return(status: 200, body: manifest.to_yaml)
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/tools_manifest/preview' do
    it 'rejects agents' do
      post "#{base_url}/preview", params: { assistant_id: assistant.id, source: source }, headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns the manifest summary, configuration fields and tools' do
      post "#{base_url}/preview", params: { assistant_id: assistant.id, source: source }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(json_response).to include(name: 'Shopify Support Tools', version: '1.2.0', revision: revision,
                                       installed_revision: nil, up_to_date: false,
                                       repository: 'chatwoot/support-tools', path: 'shopify')
      expect(json_response[:fields]).to eq([
                                             { name: 'shop_domain', section: 'inputs', label: 'Shopify store domain', type: 'string',
                                               placeholder: 'acme.myshopify.com', required: true, options: nil },
                                             { name: 'access_token', section: 'secrets', label: 'Access token', type: 'password',
                                               placeholder: nil, required: true, options: nil }
                                           ])
      expect(json_response[:tools]).to eq([{ id: 'get_order', title: 'Get Order', description: 'Retrieve an order by its ID.',
                                             http_method: 'GET' }])
    end

    it 'reports optional fields used for authentication as required' do
      manifest['secrets']['access_token']['required'] = false
      stub_request(:get, "https://raw.githubusercontent.com/chatwoot/support-tools/#{revision}/shopify/toolset.yml")
        .to_return(status: 200, body: manifest.to_yaml)

      post "#{base_url}/preview", params: { assistant_id: assistant.id, source: source }, headers: admin.create_new_auth_token, as: :json

      expect(json_response[:fields].find { |field| field[:name] == 'access_token' }[:required]).to be(true)
    end

    it 'reports an installed toolset as up to date' do
      Captain::ToolsManifest::InstallService.new(assistant: assistant, source: source, configuration: configuration.deep_stringify_keys).perform

      post "#{base_url}/preview", params: { assistant_id: assistant.id, source: source }, headers: admin.create_new_auth_token, as: :json

      expect(json_response).to include(installed_revision: revision, up_to_date: true)
    end

    it 'reports a toolset with deleted tools as not up to date' do
      manifest['tools'] << manifest['tools'].first.deep_dup.merge('id' => 'cancel_order', 'title' => 'Cancel Order')
      stub_request(:get, "https://raw.githubusercontent.com/chatwoot/support-tools/#{revision}/shopify/toolset.yml")
        .to_return(status: 200, body: manifest.to_yaml)
      Captain::ToolsManifest::InstallService.new(assistant: assistant, source: source, configuration: configuration.deep_stringify_keys).perform
      assistant.custom_tools.find_by!(title: 'Cancel Order').destroy!

      post "#{base_url}/preview", params: { assistant_id: assistant.id, source: source }, headers: admin.create_new_auth_token, as: :json

      expect(json_response).to include(installed_revision: revision, up_to_date: false)
    end

    it 'returns unprocessable entity for an invalid source' do
      post "#{base_url}/preview", params: { assistant_id: assistant.id, source: 'not-a-source' }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to eq('Enter a public GitHub URL or owner/repository/folder on the default branch')
    end

    it 'returns unprocessable entity for an invalid manifest' do
      stub_request(:get, "https://raw.githubusercontent.com/chatwoot/support-tools/#{revision}/shopify/toolset.yml")
        .to_return(status: 200, body: manifest.merge('kind' => 'toolset').to_yaml)

      post "#{base_url}/preview", params: { assistant_id: assistant.id, source: source }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to eq("This toolset's manifest is invalid")
    end
  end

  describe 'POST /api/v1/accounts/{account.id}/captain/tools_manifest/install' do
    it 'rejects agents' do
      post "#{base_url}/install", params: { assistant_id: assistant.id, source: source, configuration: configuration },
                                  headers: agent.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(assistant.custom_tools.count).to eq(0)
    end

    it 'installs a specific commit when a revision is given' do
      older_revision = 'b' * 40
      stub_request(:get, "https://raw.githubusercontent.com/chatwoot/support-tools/#{older_revision}/shopify/toolset.yml")
        .to_return(status: 200, body: manifest.to_yaml)

      post "#{base_url}/install", params: { assistant_id: assistant.id, source: source, revision: older_revision, configuration: configuration },
                                  headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(assistant.custom_tools.first.source_metadata['revision']).to eq(older_revision)
    end

    it 'installs the toolset and returns its tools' do
      post "#{base_url}/install", params: { assistant_id: assistant.id, source: source, configuration: configuration },
                                  headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(json_response[:payload].pluck(:title)).to eq(['Get Order'])
      expect(json_response[:payload].first[:source_metadata]).to include(repository: 'chatwoot/support-tools', path: 'shopify', revision: revision)
      expect(assistant.custom_tools.first.auth_config).to eq('token' => 'shpat_secret')
    end

    it 'returns unprocessable entity when the revision is not a string' do
      [123, { sha: revision }].each do |invalid_revision|
        post "#{base_url}/install", params: { assistant_id: assistant.id, source: source, revision: invalid_revision, configuration: configuration },
                                    headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity), "expected #{invalid_revision.inspect} to be rejected"
        expect(json_response[:error]).to eq('Invalid configuration')
      end
    end

    it 'installs a manifest without inputs or secrets when configuration is omitted' do
      tool = manifest['tools'].first.merge('endpoint_url' => 'https://api.example.com/orders/{{ order_id }}.json', 'auth_type' => 'none')
      fieldless_manifest = manifest.except('inputs', 'secrets').merge('tools' => [tool.except('auth_config')])
      stub_request(:get, "https://raw.githubusercontent.com/chatwoot/support-tools/#{revision}/shopify/toolset.yml")
        .to_return(status: 200, body: fieldless_manifest.to_yaml)

      post "#{base_url}/install", params: { assistant_id: assistant.id, source: source }, headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:success)
      expect(assistant.custom_tools.count).to eq(1)
    end

    it 'returns unprocessable entity when a configuration section is not an object' do
      # Optional fields only, so a silently dropped section would not trip the required check
      tool = manifest['tools'].first.merge('endpoint_url' => 'https://api.example.com/orders/{{ order_id }}.json', 'auth_type' => 'none')
      optional_manifest = manifest.except('secrets').merge('inputs' => { 'region' => { 'label' => 'Region' } },
                                                           'tools' => [tool.except('auth_config')])
      stub_request(:get, "https://raw.githubusercontent.com/chatwoot/support-tools/#{revision}/shopify/toolset.yml")
        .to_return(status: 200, body: optional_manifest.to_yaml)

      [{ inputs: 'region' }, { secrets: ['region'] }].each do |invalid_configuration|
        post "#{base_url}/install", params: { assistant_id: assistant.id, source: source, configuration: invalid_configuration },
                                    headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity), "expected #{invalid_configuration.inspect} to be rejected"
        expect(json_response[:error]).to eq('Invalid configuration')
      end
      expect(assistant.custom_tools.count).to eq(0)
    end

    it 'returns unprocessable entity for unknown configuration sections' do
      post "#{base_url}/install", params: { assistant_id: assistant.id, source: source, configuration: configuration.merge(typo: {}) },
                                  headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to eq('Invalid configuration')
      expect(assistant.custom_tools.count).to eq(0)
    end

    it 'returns unprocessable entity when the configuration is not an object' do
      ['inputs', ['inputs']].each do |invalid_configuration|
        post "#{base_url}/install", params: { assistant_id: assistant.id, source: source, configuration: invalid_configuration },
                                    headers: admin.create_new_auth_token, as: :json

        expect(response).to have_http_status(:unprocessable_entity), "expected #{invalid_configuration.inspect} to be rejected"
        expect(json_response[:error]).to eq('Invalid configuration')
      end
    end

    it 'returns unprocessable entity when a required value is missing' do
      post "#{base_url}/install",
           params: { assistant_id: assistant.id, source: source, configuration: { inputs: { shop_domain: 'acme.myshopify.com' } } },
           headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to eq('Invalid configuration')
    end

    it 'returns unprocessable entity when the assistant would exceed the tool limit' do
      create_list(:captain_custom_tool, Captain::CustomTool::MAX_PER_ASSISTANT, account: account, assistant: assistant)

      post "#{base_url}/install", params: { assistant_id: assistant.id, source: source, configuration: configuration },
                                  headers: admin.create_new_auth_token, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to eq(I18n.t('captain.custom_tool.limit_exceeded', limit: Captain::CustomTool::MAX_PER_ASSISTANT))
    end
  end
end
