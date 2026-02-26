require 'rails_helper'

RSpec.describe Captain::Mcp::DiscoveryService do
  let(:account) { create(:account) }
  let(:mcp_server) { create(:captain_mcp_server, account: account) }
  let(:service) { described_class.new(mcp_server) }

  let(:mock_tools) do
    [
      {
        'name' => 'search_docs',
        'description' => 'Search documentation',
        'inputSchema' => { 'type' => 'object', 'properties' => { 'query' => { 'type' => 'string' } } }
      },
      {
        'name' => 'get_page',
        'description' => 'Get a page by URL',
        'inputSchema' => { 'type' => 'object', 'properties' => { 'url' => { 'type' => 'string' } } }
      }
    ]
  end

  describe '#connect_and_discover' do
    let(:mock_client_service) { instance_double(Captain::Mcp::ClientService) }

    before do
      allow(Captain::Mcp::ClientService).to receive(:new).and_return(mock_client_service)
    end

    context 'when connection succeeds' do
      before do
        allow(mock_client_service).to receive(:connect).and_return(Captain::Mcp::ClientService::Result.success)
        allow(mock_client_service).to receive(:list_tools).and_return(mock_tools)
      end

      it 'connects and discovers tools' do
        result = service.connect_and_discover

        expect(result).to eq(mock_tools)
      end

      it 'caches discovered tools on the server' do
        service.connect_and_discover

        expect(mcp_server.reload.cached_tools).to eq(mock_tools)
      end

      it 'updates cache_refreshed_at timestamp' do
        freeze_time do
          service.connect_and_discover
          expect(mcp_server.reload.cache_refreshed_at).to eq(Time.current)
        end
      end
    end

    context 'when connection fails' do
      before do
        allow(mock_client_service).to receive(:connect)
          .and_return(Captain::Mcp::ClientService::Result.failure('Connection refused'))
      end

      it 'raises ConnectionError' do
        expect { service.connect_and_discover }.to raise_error(Captain::Mcp::ConnectionError, 'Connection refused')
      end
    end
  end

  describe '#refresh_tools' do
    let(:mock_client_service) { instance_double(Captain::Mcp::ClientService) }

    before do
      allow(Captain::Mcp::ClientService).to receive(:new).and_return(mock_client_service)
    end

    context 'when list_tools succeeds' do
      before do
        allow(mock_client_service).to receive(:list_tools).and_return(mock_tools)
      end

      it 'returns discovered tools' do
        result = service.refresh_tools
        expect(result).to eq(mock_tools)
      end

      it 'updates cached_tools on server' do
        service.refresh_tools
        expect(mcp_server.reload.cached_tools).to eq(mock_tools)
      end

      it 'updates cache_refreshed_at' do
        freeze_time do
          service.refresh_tools
          expect(mcp_server.reload.cache_refreshed_at).to eq(Time.current)
        end
      end
    end

    context 'when list_tools fails' do
      before do
        allow(mock_client_service).to receive(:list_tools).and_raise(StandardError.new('Network error'))
      end

      it 'raises MCP Error with context' do
        expect { service.refresh_tools }.to raise_error(Captain::Mcp::Error, /Failed to discover tools/)
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/MCP tool discovery failed/)
        expect { service.refresh_tools }.to raise_error(Captain::Mcp::Error)
      end
    end

    context 'when server has existing cached tools' do
      let(:mcp_server) { create(:captain_mcp_server, :connected, account: account) }

      before do
        allow(mock_client_service).to receive(:list_tools).and_return(mock_tools)
      end

      it 'replaces existing cached tools' do
        old_tools = mcp_server.cached_tools
        service.refresh_tools

        expect(mcp_server.reload.cached_tools).to eq(mock_tools)
        expect(mcp_server.cached_tools).not_to eq(old_tools)
      end
    end
  end
end
