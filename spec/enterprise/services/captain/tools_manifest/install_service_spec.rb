require 'rails_helper'

RSpec.describe Captain::ToolsManifest::InstallService do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:latest_revision) { 'a' * 40 }
  let(:older_revision) { 'b' * 40 }
  let(:configuration) { { 'inputs' => { 'shop_domain' => 'acme.myshopify.com' }, 'secrets' => { 'access_token' => 'shpat_secret' } } }
  let(:manifest) do
    {
      'version' => '1.2.0',
      'kind' => 'captain_toolset',
      'name' => 'Shopify Support Tools',
      'description' => 'Look up Shopify orders for support conversations.',
      'headers' => { 'x-api-version' => '2026-05-01' },
      'inputs' => { 'shop_domain' => { 'label' => 'Shopify store domain', 'required' => true } },
      'secrets' => { 'access_token' => { 'label' => 'Admin API access token', 'type' => 'password', 'required' => true } },
      'tools' => [
        {
          'id' => 'get_order',
          'title' => 'Get Order',
          'description' => 'Retrieve an order by its ID.',
          'http_method' => 'GET',
          'endpoint_url' => 'https://${{ inputs.shop_domain }}/admin/api/orders/{{ order_id }}.json',
          'auth_type' => 'api_key',
          'auth_config' => { 'name' => 'X-Shopify-Access-Token', 'key' => '${{ secrets.access_token }}' },
          'param_schema' => [{ 'name' => 'order_id', 'type' => 'string', 'description' => 'The order ID', 'required' => true }]
        },
        {
          'id' => 'cancel_order',
          'title' => 'Cancel Order',
          'description' => 'Cancel an order by its ID.',
          'http_method' => 'POST',
          'endpoint_url' => 'https://${{ inputs.shop_domain }}/admin/api/orders/{{ order_id }}/cancel.json',
          'auth_type' => 'api_key',
          'auth_config' => { 'name' => 'X-Shopify-Access-Token', 'key' => '${{ secrets.access_token }}' },
          'param_schema' => [{ 'name' => 'order_id', 'type' => 'string', 'description' => 'The order ID', 'required' => true }],
          'enabled' => false
        }
      ]
    }
  end
  let(:manifest_yaml) { manifest.to_yaml }
  let(:latest_commit_url) { 'https://api.github.com/repos/chatwoot/support-tools/commits/HEAD' }
  let(:manifest_url) { "https://raw.githubusercontent.com/chatwoot/support-tools/#{latest_revision}/shopify/toolset.yml" }

  before do
    stub_request(:get, latest_commit_url).with(headers: { 'Accept' => 'application/vnd.github.sha' }).to_return(status: 200, body: latest_revision)
    stub_request(:get, manifest_url).to_return(status: 200, body: manifest_yaml)
  end

  def install(**overrides)
    described_class.new(assistant: assistant, source: 'chatwoot/support-tools/shopify', configuration: configuration, **overrides).perform
  end

  describe '#perform' do
    it 'installs every tool from the latest commit with install-time values filled in' do
      tools = install

      expect(tools.map(&:title)).to eq(['Get Order', 'Cancel Order'])
      tool = tools.first
      expect(tool.endpoint_url).to eq('https://acme.myshopify.com/admin/api/orders/{{ order_id }}.json')
      expect(tool.auth_config).to eq('name' => 'X-Shopify-Access-Token', 'key' => 'shpat_secret')
      expect(tool.headers).to eq('x-api-version' => '2026-05-01')
      expect(tools.map(&:enabled)).to eq([true, false])
    end

    it 'records where each tool came from' do
      tools = install

      expect(tools.first.source_metadata).to include(
        'source' => 'github',
        'repository' => 'chatwoot/support-tools',
        'path' => 'shopify',
        'tool_id' => 'get_order',
        'revision' => latest_revision,
        'version' => '1.2.0',
        'manifest_digest' => "sha256:#{Digest::SHA256.hexdigest(manifest_yaml)}"
      )
      expect(tools.map { |tool| tool.source_metadata['installation_id'] }.uniq.size).to eq(1)
    end

    it 'installs a specific commit without resolving the latest one' do
      stub_request(:get, "https://raw.githubusercontent.com/chatwoot/support-tools/#{older_revision}/shopify/toolset.yml")
        .to_return(status: 200, body: manifest_yaml)

      tools = install(revision: older_revision)

      expect(tools.first.source_metadata['revision']).to eq(older_revision)
      expect(WebMock).not_to have_requested(:get, latest_commit_url)
    end

    it 'returns the existing tools when the same commit is already installed' do
      existing_ids = install.map(&:id)

      tools = install(revision: latest_revision)

      expect(tools.map(&:id)).to match_array(existing_ids)
      expect(WebMock).to have_requested(:get, manifest_url).once
      expect(assistant.custom_tools.count).to eq(2)
    end

    context 'when a different commit is already installed' do
      let!(:installed_tools) do
        stub_request(:get, "https://raw.githubusercontent.com/chatwoot/support-tools/#{older_revision}/shopify/toolset.yml")
          .to_return(status: 200, body: manifest_yaml)
        install(revision: older_revision)
      end

      before do
        installed_tools.first.update!(enabled: false)
        manifest['tools'].first['title'] = 'Find Order'
        manifest['tools'][1] = manifest['tools'][1].merge('id' => 'refund_order', 'title' => 'Refund Order', 'enabled' => true)
        stub_request(:get, manifest_url).to_return(status: 200, body: manifest.to_yaml)
      end

      it 'updates matching tools in place and keeps their slug and enabled state' do
        tools = install

        updated = tools.find { |tool| tool.source_metadata['tool_id'] == 'get_order' }
        expect(updated.id).to eq(installed_tools.first.id)
        expect(updated.title).to eq('Find Order')
        expect(updated.slug).to eq(installed_tools.first.slug)
        expect(updated.enabled).to be(false)
        expect(updated.source_metadata['revision']).to eq(latest_revision)
        expect(updated.source_metadata['installation_id']).to eq(installed_tools.first.source_metadata['installation_id'])
      end

      it 'creates tools added to the manifest and deletes tools it dropped' do
        install

        expect(assistant.custom_tools.map { |tool| tool.source_metadata['tool_id'] }).to contain_exactly('get_order', 'refund_order')
      end
    end

    context 'with a GitHub token configured' do
      before { create(:installation_config, name: 'CAPTAIN_TOOLS_GITHUB_TOKEN', value: 'github_pat_valid') }

      it 'authenticates the latest commit lookup but not the manifest download' do
        install

        expect(WebMock).to have_requested(:get, latest_commit_url).with(headers: { 'Authorization' => 'Bearer github_pat_valid' })
        expect(WebMock).to(have_requested(:get, manifest_url).with { |request| !request.headers.key?('Authorization') })
      end

      it 'falls back to an unauthenticated lookup when GitHub rejects the token' do
        stub_request(:get, latest_commit_url)
          .with(headers: { 'Authorization' => 'Bearer github_pat_valid' })
          .to_return(status: 401, body: 'Bad credentials')

        tools = install

        expect(tools.first.source_metadata['revision']).to eq(latest_revision)
        expect(WebMock).to(have_requested(:get, latest_commit_url).with { |request| !request.headers.key?('Authorization') })
      end
    end

    it 'looks up the latest commit without a token when none is configured' do
      install

      expect(WebMock).to(have_requested(:get, latest_commit_url).with { |request| !request.headers.key?('Authorization') })
    end

    it 'rejects a source that is not owner/repository/folder' do
      expect { install(source: 'chatwoot/support-tools') }.to raise_error(described_class::InstallError, %r{owner/repository/folder})
    end

    it 'rejects an abbreviated revision' do
      expect { install(revision: 'abc1234') }.to raise_error(described_class::InstallError, /40-character commit SHA/)
    end

    it 'rejects missing required values' do
      configuration['secrets'] = {}

      expect { install }.to raise_error(described_class::InstallError, /Admin API access token is required/)
    end

    it 'rejects values the manifest does not declare' do
      configuration['inputs']['region'] = 'us'

      expect { install }.to raise_error(described_class::InstallError, /Unknown inputs: region/)
    end

    it 'raises when the manifest cannot be fetched' do
      stub_request(:get, manifest_url).to_return(status: 404, body: 'Not Found')

      expect { install }.to raise_error(described_class::InstallError, /Could not fetch/)
    end

    it 'raises when the manifest is invalid' do
      manifest['kind'] = 'toolset'
      stub_request(:get, manifest_url).to_return(status: 200, body: manifest.to_yaml)

      expect { install }.to raise_error(Captain::ToolsManifest::Validator::InvalidManifestError)
    end

    it 'creates nothing when a tool fails validation' do
      configuration['inputs']['shop_domain'] = 'localhost'

      expect { install }.to raise_error(described_class::InstallError, /Get Order/)
      expect(assistant.custom_tools.count).to eq(0)
    end

    it 'creates nothing when the assistant would exceed the tool limit' do
      create_list(:captain_custom_tool, Captain::CustomTool::MAX_PER_ASSISTANT - 1, account: account, assistant: assistant)

      expect { install }.to raise_error(Captain::CustomTool::LimitExceededError)
      expect(assistant.custom_tools.count).to eq(Captain::CustomTool::MAX_PER_ASSISTANT - 1)
    end
  end
end
