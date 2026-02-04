require 'rails_helper'

RSpec.describe Captain::AssistantMcpServer, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:assistant).class_name('Captain::Assistant') }
    it { is_expected.to belong_to(:mcp_server).class_name('Captain::McpServer') }
  end

  describe 'validations' do
    let(:account) { create(:account) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:mcp_server) { create(:captain_mcp_server, account: account) }

    it 'validates uniqueness of assistant and mcp_server combination' do
      create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server)
      duplicate = build(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:captain_assistant_id]).to include('has already been taken')
    end

    it 'allows same server attached to different assistants' do
      assistant2 = create(:captain_assistant, account: account)
      create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server)
      different_assistant_attachment = build(:captain_assistant_mcp_server, assistant: assistant2, mcp_server: mcp_server)

      expect(different_assistant_attachment).to be_valid
    end
  end

  describe 'scopes' do
    let(:account) { create(:account) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:mcp_server) { create(:captain_mcp_server, :connected, account: account) }

    describe '.enabled' do
      it 'returns only enabled attachments' do
        enabled = create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server, enabled: true)
        create(:captain_assistant_mcp_server, :disabled, assistant: create(:captain_assistant, account: account), mcp_server: mcp_server)

        expect(described_class.enabled).to contain_exactly(enabled)
      end
    end
  end

  describe '#filtered_tools' do
    let(:account) { create(:account) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:mcp_server) { create(:captain_mcp_server, :connected, account: account) }

    it 'returns all tools when no filters' do
      attachment = create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server, tool_filters: {})

      expect(attachment.filtered_tools.length).to eq(2)
      expect(attachment.filtered_tools.map { |t| t['name'] }).to contain_exactly('search_docs', 'get_page')
    end

    it 'filters tools by include list' do
      attachment = create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server,
                                                         tool_filters: { 'include' => ['search_docs'] })

      expect(attachment.filtered_tools.length).to eq(1)
      expect(attachment.filtered_tools.first['name']).to eq('search_docs')
    end

    it 'filters tools by exclude list' do
      attachment = create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server,
                                                         tool_filters: { 'exclude' => ['get_page'] })

      expect(attachment.filtered_tools.length).to eq(1)
      expect(attachment.filtered_tools.first['name']).to eq('search_docs')
    end

    it 'applies both include and exclude filters' do
      attachment = create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server,
                                                         tool_filters: { 'include' => %w[search_docs get_page], 'exclude' => ['get_page'] })

      expect(attachment.filtered_tools.length).to eq(1)
      expect(attachment.filtered_tools.first['name']).to eq('search_docs')
    end

    it 'returns empty array when server has no cached tools' do
      mcp_server.update!(cached_tools: nil)
      attachment = create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server)

      expect(attachment.filtered_tools).to eq([])
    end
  end

  describe '#to_tool_metadata' do
    let(:account) { create(:account) }
    let(:assistant) { create(:captain_assistant, account: account) }
    let(:mcp_server) { create(:captain_mcp_server, :connected, account: account) }

    it 'returns metadata for filtered tools' do
      attachment = create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server,
                                                         tool_filters: { 'include' => ['search_docs'] })

      metadata = attachment.to_tool_metadata

      expect(metadata.length).to eq(1)
      expect(metadata.first[:id]).to eq("#{mcp_server.slug}_search_docs")
      expect(metadata.first[:title]).to eq('Search Docs')
      expect(metadata.first[:mcp]).to be true
      expect(metadata.first[:mcp_server_id]).to eq(mcp_server.id)
    end

    it 'returns all tool metadata when no filters' do
      attachment = create(:captain_assistant_mcp_server, assistant: assistant, mcp_server: mcp_server)

      metadata = attachment.to_tool_metadata

      expect(metadata.length).to eq(2)
    end
  end

  describe 'factory' do
    it 'creates a valid assistant MCP server with default attributes' do
      attachment = create(:captain_assistant_mcp_server)

      expect(attachment).to be_valid
      expect(attachment.assistant).to be_present
      expect(attachment.mcp_server).to be_present
      expect(attachment.enabled).to be true
      expect(attachment.tool_filters).to eq({})
    end

    it 'creates valid attachment with include filter trait' do
      attachment = create(:captain_assistant_mcp_server, :with_include_filter)

      expect(attachment.tool_filters['include']).to eq(['search_docs'])
    end

    it 'creates valid attachment with exclude filter trait' do
      attachment = create(:captain_assistant_mcp_server, :with_exclude_filter)

      expect(attachment.tool_filters['exclude']).to eq(['get_page'])
    end
  end
end
