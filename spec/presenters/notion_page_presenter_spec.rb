require 'rails_helper'

RSpec.describe NotionPagePresenter do
  subject(:presenter) { described_class.new(page_response, blocks_response) }

  let(:page_response) do
    {
      'id' => 'page-123',
      'icon' => { 'emoji' => '📄' },
      'created_time' => '2023-01-01T10:00:00.000Z',
      'last_edited_time' => '2023-01-02T15:30:00.000Z',
      'properties' => {
        'title' => {
          'type' => 'title',
          'title' => [
            { 'plain_text' => 'Test Page Title' }
          ]
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
            'rich_text' => [
              { 'plain_text' => 'This is a paragraph.' }
            ]
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

  let(:markdown_converter) { instance_double(NotionToMarkdown) }

  before do
    allow(NotionToMarkdown).to receive(:new).and_return(markdown_converter)
    allow(markdown_converter).to receive(:convert).and_return('This is a paragraph.')
  end

  describe '#to_hash' do
    it 'returns a properly formatted hash with all required fields' do
      result = presenter.to_hash

      expect(result).to include(
        'id' => 'page-123',
        'icon' => { 'emoji' => '📄' },
        'title' => 'Test Page Title',
        'created_time' => '2023-01-01T10:00:00.000Z',
        'last_edited_time' => '2023-01-02T15:30:00.000Z'
      )
    end

    it 'includes markdown content with title as H1' do
      result = presenter.to_hash

      expect(result['md']).to eq("# Test Page Title\n\nThis is a paragraph.")
    end

    it 'includes child pages with id and title' do
      result = presenter.to_hash

      expect(result['child_pages']).to eq([
                                            {
                                              'id' => 'child-page-1',
                                              'title' => 'Child Page 1'
                                            }
                                          ])
    end

    it 'calls NotionToMarkdown converter with blocks' do
      presenter.to_hash

      expect(markdown_converter).to have_received(:convert).with(blocks_response['results'])
    end

    context 'when page has no title in properties' do
      let(:page_response) do
        {
          'id' => 'page-123',
          'icon' => nil,
          'created_time' => '2023-01-01T10:00:00.000Z',
          'last_edited_time' => '2023-01-02T15:30:00.000Z',
          'properties' => {}
        }
      end

      it 'returns nil for title and no H1 in markdown' do
        result = presenter.to_hash

        expect(result['title']).to be_nil
        expect(result['md']).to eq('This is a paragraph.')
      end
    end

    context 'when page has no properties' do
      let(:page_response) do
        {
          'id' => 'page-123',
          'icon' => nil,
          'created_time' => '2023-01-01T10:00:00.000Z',
          'last_edited_time' => '2023-01-02T15:30:00.000Z'
        }
      end

      it 'returns nil for title' do
        result = presenter.to_hash

        expect(result['title']).to be_nil
      end
    end

    context 'with nested child pages' do
      let(:blocks_response) do
        {
          'results' => [
            {
              'type' => 'toggle',
              'has_children' => true,
              'children' => [
                {
                  'type' => 'child_page',
                  'id' => 'nested-child-1',
                  'child_page' => {
                    'title' => 'Nested Child Page'
                  }
                }
              ]
            },
            {
              'type' => 'child_page',
              'id' => 'top-level-child',
              'child_page' => {
                'title' => 'Top Level Child'
              }
            }
          ]
        }
      end

      it 'extracts all child pages including nested ones' do
        result = presenter.to_hash

        expect(result['child_pages']).to contain_exactly(
          {
            'id' => 'nested-child-1',
            'title' => 'Nested Child Page'
          },
          {
            'id' => 'top-level-child',
            'title' => 'Top Level Child'
          }
        )
      end
    end

    context 'when blocks response has no child pages' do
      let(:blocks_response) do
        {
          'results' => [
            {
              'type' => 'paragraph',
              'paragraph' => {
                'rich_text' => [
                  { 'plain_text' => 'Just a paragraph.' }
                ]
              }
            }
          ]
        }
      end

      it 'returns empty child_pages array' do
        result = presenter.to_hash

        expect(result['child_pages']).to eq([])
      end
    end

    context 'when blocks response is empty' do
      let(:blocks_response) { { 'results' => [] } }

      it 'handles empty blocks gracefully' do
        allow(markdown_converter).to receive(:convert).with([]).and_return('')

        result = presenter.to_hash

        expect(result['md']).to eq("# Test Page Title\n\n")
        expect(result['child_pages']).to eq([])
      end
    end
  end
end