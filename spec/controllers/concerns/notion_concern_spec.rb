require 'rails_helper'

RSpec.describe NotionConcern, type: :concern do
  let(:controller_class) do
    Class.new do
      include NotionConcern
    end
  end

  let(:controller) { controller_class.new }

  describe '#notion_client' do
    let(:client_id) { 'test_notion_client_id' }
    let(:client_secret) { 'test_notion_client_secret' }

    before do
      allow(GlobalConfigService).to receive(:load).with('NOTION_CLIENT_ID', nil).and_return(client_id)
      allow(GlobalConfigService).to receive(:load).with('NOTION_CLIENT_SECRET', nil).and_return(client_secret)
    end

    it 'creates OAuth2 client with correct configuration' do
      expect(OAuth2::Client).to receive(:new).with(
        client_id,
        client_secret,
        {
          site: 'https://api.notion.com',
          authorize_url: 'https://api.notion.com/v1/oauth/authorize',
          token_url: 'https://api.notion.com/v1/oauth/token',
          auth_scheme: :basic_auth
        }
      )

      controller.notion_client
    end

    it 'loads client credentials from GlobalConfigService' do
      expect(GlobalConfigService).to receive(:load).with('NOTION_CLIENT_ID', nil)
      expect(GlobalConfigService).to receive(:load).with('NOTION_CLIENT_SECRET', nil)

      controller.notion_client
    end

    it 'returns OAuth2::Client instance' do
      client = controller.notion_client
      expect(client).to be_an_instance_of(OAuth2::Client)
    end

    it 'configures client with Notion-specific endpoints' do
      client = controller.notion_client
      expect(client.site).to eq('https://api.notion.com')
      expect(client.options[:authorize_url]).to eq('https://api.notion.com/v1/oauth/authorize')
      expect(client.options[:token_url]).to eq('https://api.notion.com/v1/oauth/token')
      expect(client.options[:auth_scheme]).to eq(:basic_auth)
    end
  end
end
