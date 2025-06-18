require 'rails_helper'

RSpec.describe Integrations::Notion::ProcessorService do
  subject(:service) { described_class.new(account: account) }

  let(:account) { create(:account) }
  let(:notion_hook) { create(:integrations_hook, account: account, app_id: 'notion', access_token: 'notion_token') }
  let(:notion_client) { instance_double(Notion) }

  before do
    notion_hook
    allow(Notion).to receive(:new).with('notion_token').and_return(notion_client)
  end

  describe '#search_pages' do
    let(:query) { 'test query' }
    let(:sort) { { direction: 'ascending', timestamp: 'last_edited_time' } }

    context 'when search is successful' do
      let(:search_response) { { 'results' => [{ 'id' => '123', 'object' => 'page' }] } }

      before do
        allow(notion_client).to receive(:search).with(query, sort).and_return(search_response)
      end

      it 'returns formatted data' do
        result = service.search_pages(query, sort)
        expect(result).to eq([{ 'id' => '123', 'object' => 'page' }])
      end
    end

    context 'when search fails' do
      let(:error_response) { { error: 'API error', error_code: 400 } }

      before do
        allow(notion_client).to receive(:search).with(query, sort).and_return(error_response)
      end

      it 'returns error' do
        result = service.search_pages(query, sort)
        expect(result).to eq({ error: 'API error' })
      end
    end
  end

  describe '#page' do
    let(:page_id) { 'page-123' }

    context 'when page retrieval is successful' do
      let(:page_response) { { 'id' => page_id, 'object' => 'page' } }

      before do
        allow(notion_client).to receive(:page).with(page_id).and_return(page_response)
      end

      it 'returns formatted data' do
        result = service.page(page_id)
        expect(result).to eq({ 'id' => page_id, 'object' => 'page' })
      end
    end

    context 'when page retrieval fails' do
      let(:error_response) { { error: 'Page not found', error_code: 404 } }

      before do
        allow(notion_client).to receive(:page).with(page_id).and_return(error_response)
      end

      it 'returns error' do
        result = service.page(page_id)
        expect(result).to eq({ error: 'Page not found' })
      end
    end
  end

  describe '#page_md' do
    let(:page_id) { 'page-123' }

    context 'when page blocks retrieval is successful' do
      let(:blocks_response) do
        {
          'results' => [
            {
              'type' => 'paragraph',
              'paragraph' => {
                'rich_text' => [{ 'plain_text' => 'Hello world' }]
              }
            }
          ]
        }
      end
      let(:markdown_converter) { instance_double(NotionToMarkdown) }

      before do
        allow(notion_client).to receive(:page_blocks).with(page_id).and_return(blocks_response)
        allow(NotionToMarkdown).to receive(:new).and_return(markdown_converter)
        allow(markdown_converter).to receive(:convert).with(blocks_response['results']).and_return('Hello world')
      end

      it 'returns markdown content' do
        result = service.page_md(page_id)
        expect(result).to eq('Hello world')
      end

      it 'calls NotionToMarkdown converter with blocks' do
        service.page_md(page_id)
        expect(markdown_converter).to have_received(:convert).with(blocks_response['results'])
      end
    end

    context 'when page blocks retrieval fails' do
      let(:error_response) { { error: 'Page not found', error_code: 404 } }

      before do
        allow(notion_client).to receive(:page_blocks).with(page_id).and_return(error_response)
      end

      it 'returns error' do
        result = service.page_md(page_id)
        expect(result).to eq({ error: 'Page not found' })
      end
    end
  end

  describe 'private methods' do
    describe '#notion_hook' do
      it 'finds the notion hook for the account' do
        expect(service.send(:notion_hook)).to eq(notion_hook)
      end

      it 'raises error if hook not found' do
        notion_hook.destroy!
        expect { service.send(:notion_hook) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe '#notion_client' do
      it 'creates a Notion client with the hook access token' do
        client = service.send(:notion_client)
        expect(Notion).to have_received(:new).with('notion_token')
        expect(client).to eq(notion_client)
      end
    end
  end
end