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
      let(:search_response) do
        {
          'results' => [
            {
              'id' => '123',
              'icon' => { 'emoji' => '📄' },
              'created_time' => '2023-01-01T10:00:00.000Z',
              'last_edited_time' => '2023-01-02T15:30:00.000Z',
              'properties' => {
                'title' => {
                  'type' => 'title',
                  'title' => [{ 'plain_text' => 'Test Page' }]
                }
              }
            }
          ]
        }
      end

      before do
        allow(notion_client).to receive(:search).with(query, sort).and_return(search_response)
      end

      it 'returns formatted pages with selected fields' do
        result = service.search_pages(query, sort)
        expect(result).to eq([
                               {
                                 'id' => '123',
                                 'icon' => { 'emoji' => '📄' },
                                 'title' => 'Test Page',
                                 'created_time' => '2023-01-01T10:00:00.000Z',
                                 'last_edited_time' => '2023-01-02T15:30:00.000Z'
                               }
                             ])
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
      let(:page_response) do
        {
          'id' => page_id,
          'icon' => { 'emoji' => '📄' },
          'created_time' => '2023-01-01T10:00:00.000Z',
          'last_edited_time' => '2023-01-02T15:30:00.000Z',
          'properties' => {
            'title' => {
              'type' => 'title',
              'title' => [{ 'plain_text' => 'Test Page' }]
            }
          }
        }
      end

      before do
        allow(notion_client).to receive(:page).with(page_id).and_return(page_response)
      end

      it 'returns formatted page data' do
        result = service.page(page_id)
        expect(result).to eq({
                               'id' => page_id,
                               'icon' => { 'emoji' => '📄' },
                               'title' => 'Test Page',
                               'created_time' => '2023-01-01T10:00:00.000Z',
                               'last_edited_time' => '2023-01-02T15:30:00.000Z'
                             })
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

  describe '#full_page' do
    let(:page_id) { 'page-123' }

    context 'when both page and blocks retrieval are successful' do
      let(:page_response) do
        {
          'id' => page_id,
          'icon' => { 'emoji' => '📄' },
          'created_time' => '2023-01-01T10:00:00.000Z',
          'last_edited_time' => '2023-01-02T15:30:00.000Z',
          'properties' => {
            'title' => {
              'type' => 'title',
              'title' => [{ 'plain_text' => 'Test Page' }]
            }
          }
        }
      end

      let(:blocks_response) do
        {
          'results' => [
            {
              'type' => 'paragraph',
              'paragraph' => {
                'rich_text' => [{ 'plain_text' => 'Hello world' }]
              }
            },
            {
              'type' => 'child_page',
              'id' => 'child-page-1',
              'child_page' => {
                'title' => 'Child Page 1'
              }
            }
          ]
        }
      end

      let(:presenter) { instance_double(NotionPagePresenter) }
      let(:presenter_result) do
        {
          'id' => page_id,
          'icon' => { 'emoji' => '📄' },
          'title' => 'Test Page',
          'created_time' => '2023-01-01T10:00:00.000Z',
          'last_edited_time' => '2023-01-02T15:30:00.000Z',
          'md' => "# Test Page\n\nHello world",
          'child_pages' => [
            {
              'id' => 'child-page-1',
              'title' => 'Child Page 1'
            }
          ]
        }
      end

      before do
        allow(notion_client).to receive(:page).with(page_id).and_return(page_response)
        allow(notion_client).to receive(:page_blocks).with(page_id).and_return(blocks_response)
        allow(NotionPagePresenter).to receive(:new).with(page_response, blocks_response).and_return(presenter)
        allow(presenter).to receive(:to_hash).and_return(presenter_result)
      end

      it 'returns complete page data with markdown and child pages' do
        result = service.full_page(page_id)
        expect(result).to eq(presenter_result)
      end

      it 'creates presenter with page and blocks responses' do
        service.full_page(page_id)
        expect(NotionPagePresenter).to have_received(:new).with(page_response, blocks_response)
      end

      it 'calls to_hash on the presenter' do
        service.full_page(page_id)
        expect(presenter).to have_received(:to_hash)
      end
    end

    context 'when page retrieval fails' do
      let(:error_response) { { error: 'Page not found', error_code: 404 } }

      before do
        allow(notion_client).to receive(:page).with(page_id).and_return(error_response)
        allow(notion_client).to receive(:page_blocks)
      end

      it 'returns error without calling page_blocks' do
        result = service.full_page(page_id)
        expect(result).to eq({ error: 'Page not found' })
        expect(notion_client).not_to have_received(:page_blocks)
      end
    end

    context 'when page blocks retrieval fails' do
      let(:page_response) { { 'id' => page_id, 'title' => 'Test Page' } }
      let(:error_response) { { error: 'Blocks not found', error_code: 404 } }

      before do
        allow(notion_client).to receive(:page).with(page_id).and_return(page_response)
        allow(notion_client).to receive(:page_blocks).with(page_id).and_return(error_response)
        allow(NotionPagePresenter).to receive(:new)
      end

      it 'returns error without calling presenter' do
        result = service.full_page(page_id)
        expect(result).to eq({ error: 'Blocks not found' })
        expect(NotionPagePresenter).not_to have_received(:new)
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