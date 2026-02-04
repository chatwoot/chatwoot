require 'rails_helper'

RSpec.describe Captain::McpServer, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:assistant_mcp_servers).dependent(:destroy) }
    it { is_expected.to have_many(:assistants).through(:assistant_mcp_servers) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:url) }

    it {
      expect(subject).to define_enum_for(:auth_type)
        .with_values('none' => 'none', 'bearer' => 'bearer', 'api_key' => 'api_key')
        .backed_by_column_of_type(:string)
        .with_prefix(:auth)
    }

    it {
      expect(subject).to define_enum_for(:status)
        .with_values('disconnected' => 'disconnected', 'connecting' => 'connecting',
                     'connected' => 'connected', 'error' => 'error')
        .backed_by_column_of_type(:string)
        .with_prefix(:connection)
    }

    describe 'slug uniqueness' do
      let(:account) { create(:account) }

      it 'validates uniqueness of slug scoped to account' do
        create(:captain_mcp_server, account: account, slug: 'mcp_test_server')
        duplicate = build(:captain_mcp_server, account: account, slug: 'mcp_test_server')

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:slug]).to include('has already been taken')
      end

      it 'allows same slug across different accounts' do
        account2 = create(:account)
        create(:captain_mcp_server, account: account, slug: 'mcp_test_server')
        different_account_server = build(:captain_mcp_server, account: account2, slug: 'mcp_test_server')

        expect(different_account_server).to be_valid
      end
    end

    describe 'URL validation' do
      let(:account) { create(:account) }

      it 'is valid with HTTPS URL' do
        server = build(:captain_mcp_server, account: account, url: 'https://mcp.example.com/api')
        expect(server).to be_valid
      end

      it 'is valid with HTTP URL' do
        server = build(:captain_mcp_server, account: account, url: 'http://mcp.example.com/api')
        expect(server).to be_valid
      end

      it 'is invalid with non-HTTP URL' do
        server = build(:captain_mcp_server, account: account, url: 'ftp://mcp.example.com')
        expect(server).not_to be_valid
        expect(server.errors[:url]).to be_present
      end

      it 'is invalid with malformed URL' do
        server = build(:captain_mcp_server, account: account, url: 'not-a-url')
        expect(server).not_to be_valid
        expect(server.errors[:url]).to be_present
      end

      it 'is invalid with localhost URL' do
        server = build(:captain_mcp_server, account: account, url: 'http://localhost/api')
        expect(server).not_to be_valid
        expect(server.errors[:url]).to be_present
      end

      it 'is invalid with .local domain URL' do
        server = build(:captain_mcp_server, account: account, url: 'http://myserver.local/api')
        expect(server).not_to be_valid
        expect(server.errors[:url]).to be_present
      end

      it 'is invalid with IP address URL' do
        server = build(:captain_mcp_server, account: account, url: 'http://192.168.1.1/api')
        expect(server).not_to be_valid
        expect(server.errors[:url]).to be_present
      end

      it 'is invalid with IPv6 address URL' do
        server = build(:captain_mcp_server, account: account, url: 'http://[::1]/api')
        expect(server).not_to be_valid
        expect(server.errors[:url]).to be_present
      end
    end
  end

  describe 'scopes' do
    let(:account) { create(:account) }

    describe '.enabled' do
      it 'returns only enabled MCP servers' do
        enabled_server = create(:captain_mcp_server, account: account, enabled: true)
        create(:captain_mcp_server, account: account, enabled: false)

        expect(described_class.enabled).to contain_exactly(enabled_server)
      end
    end

    describe '.connected' do
      it 'returns only connected MCP servers' do
        connected_server = create(:captain_mcp_server, :connected, account: account)
        create(:captain_mcp_server, account: account, status: 'disconnected')

        expect(described_class.connected).to contain_exactly(connected_server)
      end
    end
  end

  describe 'slug generation' do
    let(:account) { create(:account) }

    it 'generates slug from name on creation' do
      server = create(:captain_mcp_server, account: account, name: 'Cloudflare Docs')
      expect(server.slug).to eq('mcp_cloudflare_docs')
    end

    it 'adds mcp_ prefix to generated slug' do
      server = create(:captain_mcp_server, account: account, name: 'My Server')
      expect(server.slug).to start_with('mcp_')
    end

    it 'does not override manually set slug' do
      server = create(:captain_mcp_server, account: account, name: 'Test Server', slug: 'mcp_manual_slug')
      expect(server.slug).to eq('mcp_manual_slug')
    end

    it 'handles slug collisions by appending random suffix' do
      create(:captain_mcp_server, account: account, name: 'Test Server', slug: 'mcp_test_server')
      server2 = create(:captain_mcp_server, account: account, name: 'Test Server')

      expect(server2.slug).to match(/^mcp_test_server_[a-z0-9]{6}$/)
    end

    it 'parameterizes name correctly' do
      server = create(:captain_mcp_server, account: account, name: 'My Server & Tools!')
      expect(server.slug).to eq('mcp_my_server_tools')
    end
  end

  describe 'status management' do
    let(:account) { create(:account) }
    let(:server) { create(:captain_mcp_server, account: account) }

    describe '#mark_connected!' do
      it 'updates status to connected' do
        server.mark_connected!

        expect(server.status).to eq('connected')
        expect(server.last_connected_at).to be_present
        expect(server.last_error).to be_nil
      end
    end

    describe '#mark_error!' do
      it 'updates status to error with message' do
        server.mark_error!('Connection refused')

        expect(server.status).to eq('error')
        expect(server.last_error).to eq('Connection refused')
      end
    end

    describe '#mark_disconnected!' do
      it 'updates status to disconnected' do
        server.update!(status: 'connected')
        server.mark_disconnected!

        expect(server.status).to eq('disconnected')
      end
    end
  end

  describe '#to_tool_metadata' do
    let(:account) { create(:account) }
    let(:server) { create(:captain_mcp_server, :connected, account: account) }

    it 'returns array of tool metadata hashes' do
      metadata = server.to_tool_metadata

      expect(metadata).to be_an(Array)
      expect(metadata.length).to eq(2)

      first_tool = metadata.first
      expect(first_tool[:id]).to eq("#{server.slug}_search_docs")
      expect(first_tool[:title]).to eq('Search Docs')
      expect(first_tool[:description]).to eq('Search documentation')
      expect(first_tool[:mcp]).to be true
      expect(first_tool[:mcp_server_id]).to eq(server.id)
      expect(first_tool[:mcp_tool_name]).to eq('search_docs')
    end

    it 'returns empty array when no cached tools' do
      server.update!(cached_tools: nil)
      expect(server.to_tool_metadata).to eq([])
    end
  end

  describe '#build_auth_headers' do
    let(:account) { create(:account) }

    it 'returns empty hash for none auth type' do
      server = create(:captain_mcp_server, account: account, auth_type: 'none')
      expect(server.build_auth_headers).to eq({})
    end

    it 'returns bearer token header' do
      server = create(:captain_mcp_server, :with_bearer_auth, account: account)
      expect(server.build_auth_headers).to eq({ 'Authorization' => 'Bearer test_bearer_token_123' })
    end

    it 'returns API key header' do
      server = create(:captain_mcp_server, :with_api_key, account: account)
      expect(server.build_auth_headers).to eq({ 'X-API-Key' => 'test_api_key' })
    end
  end

  describe 'factory' do
    it 'creates a valid MCP server with default attributes' do
      server = create(:captain_mcp_server)

      expect(server).to be_valid
      expect(server.name).to be_present
      expect(server.slug).to be_present
      expect(server.url).to be_present
      expect(server.auth_type).to eq('none')
      expect(server.status).to eq('disconnected')
      expect(server.enabled).to be true
    end

    it 'creates valid server with connected trait' do
      server = create(:captain_mcp_server, :connected)

      expect(server.status).to eq('connected')
      expect(server.cached_tools).to be_present
      expect(server.last_connected_at).to be_present
    end

    it 'creates valid server with bearer auth trait' do
      server = create(:captain_mcp_server, :with_bearer_auth)

      expect(server.auth_type).to eq('bearer')
      expect(server.auth_config['token']).to eq('test_bearer_token_123')
    end

    it 'creates valid server with API key trait' do
      server = create(:captain_mcp_server, :with_api_key)

      expect(server.auth_type).to eq('api_key')
      expect(server.auth_config['key']).to eq('test_api_key')
    end
  end
end
