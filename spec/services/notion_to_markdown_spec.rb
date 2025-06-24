require 'rails_helper'

RSpec.describe NotionToMarkdown do
  subject(:converter) { described_class.new }

  describe '#convert' do
    context 'with paragraph blocks' do
      let(:blocks) do
        [
          {
            'type' => 'paragraph',
            'paragraph' => {
              'rich_text' => [
                { 'plain_text' => 'This is a simple paragraph.' }
              ]
            }
          }
        ]
      end

      it 'converts paragraph to markdown' do
        result = converter.convert(blocks)
        expect(result).to eq('This is a simple paragraph.')
      end
    end

    context 'with heading blocks' do
      let(:blocks) do
        [
          {
            'type' => 'heading_1',
            'heading_1' => {
              'rich_text' => [{ 'plain_text' => 'Main Title' }]
            }
          },
          {
            'type' => 'heading_2',
            'heading_2' => {
              'rich_text' => [{ 'plain_text' => 'Subtitle' }]
            }
          },
          {
            'type' => 'heading_3',
            'heading_3' => {
              'rich_text' => [{ 'plain_text' => 'Sub-subtitle' }]
            }
          }
        ]
      end

      it 'converts headings to markdown' do
        result = converter.convert(blocks)
        expected = "# Main Title\n\n## Subtitle\n\n### Sub-subtitle"
        expect(result).to eq(expected)
      end
    end

    context 'with list blocks' do
      let(:blocks) do
        [
          {
            'type' => 'bulleted_list_item',
            'bulleted_list_item' => {
              'rich_text' => [{ 'plain_text' => 'First bullet point' }]
            }
          },
          {
            'type' => 'numbered_list_item',
            'numbered_list_item' => {
              'rich_text' => [{ 'plain_text' => 'First numbered item' }]
            }
          }
        ]
      end

      it 'converts lists to markdown' do
        result = converter.convert(blocks)
        expected = "- First bullet point\n\n1. First numbered item"
        expect(result).to eq(expected)
      end
    end

    context 'with to-do blocks' do
      let(:blocks) do
        [
          {
            'type' => 'to_do',
            'to_do' => {
              'checked' => false,
              'rich_text' => [{ 'plain_text' => 'Incomplete task' }]
            }
          },
          {
            'type' => 'to_do',
            'to_do' => {
              'checked' => true,
              'rich_text' => [{ 'plain_text' => 'Completed task' }]
            }
          }
        ]
      end

      it 'converts to-dos to markdown' do
        result = converter.convert(blocks)
        expected = "- [ ] Incomplete task\n\n- [x] Completed task"
        expect(result).to eq(expected)
      end
    end

    context 'with rich text formatting' do
      let(:blocks) do
        [
          {
            'type' => 'paragraph',
            'paragraph' => {
              'rich_text' => [
                {
                  'plain_text' => 'This is bold',
                  'annotations' => { 'bold' => true }
                },
                { 'plain_text' => ' and ' },
                {
                  'plain_text' => 'this is italic',
                  'annotations' => { 'italic' => true }
                },
                { 'plain_text' => ' and ' },
                {
                  'plain_text' => 'this is code',
                  'annotations' => { 'code' => true }
                }
              ]
            }
          }
        ]
      end

      it 'applies rich text formatting' do
        result = converter.convert(blocks)
        expected = '**This is bold** and *this is italic* and `this is code`'
        expect(result).to eq(expected)
      end
    end

    context 'with links' do
      let(:blocks) do
        [
          {
            'type' => 'paragraph',
            'paragraph' => {
              'rich_text' => [
                {
                  'plain_text' => 'Visit our website',
                  'href' => 'https://example.com'
                }
              ]
            }
          }
        ]
      end

      it 'converts links to markdown' do
        result = converter.convert(blocks)
        expected = '[Visit our website](https://example.com)'
        expect(result).to eq(expected)
      end
    end

    context 'with code blocks' do
      let(:blocks) do
        [
          {
            'type' => 'code',
            'code' => {
              'language' => 'javascript',
              'rich_text' => [
                { 'plain_text' => "console.log('Hello, world!');" }
              ]
            }
          }
        ]
      end

      it 'converts code blocks to markdown' do
        result = converter.convert(blocks)
        expected = "```javascript\nconsole.log('Hello, world!');\n```"
        expect(result).to eq(expected)
      end
    end

    context 'with quote blocks' do
      let(:blocks) do
        [
          {
            'type' => 'quote',
            'quote' => {
              'rich_text' => [
                { 'plain_text' => 'This is a quote' }
              ]
            }
          }
        ]
      end

      it 'converts quotes to markdown' do
        result = converter.convert(blocks)
        expected = '> This is a quote'
        expect(result).to eq(expected)
      end
    end

    context 'with callout blocks' do
      let(:blocks) do
        [
          {
            'type' => 'callout',
            'callout' => {
              'icon' => { 'emoji' => '⚠️' },
              'rich_text' => [
                { 'plain_text' => 'This is a warning' }
              ]
            }
          }
        ]
      end

      it 'converts callouts to markdown' do
        result = converter.convert(blocks)
        expected = '> [!⚠️] This is a warning'
        expect(result).to eq(expected)
      end
    end

    context 'with divider blocks' do
      let(:blocks) do
        [
          {
            'type' => 'divider',
            'divider' => {}
          }
        ]
      end

      it 'converts dividers to markdown' do
        result = converter.convert(blocks)
        expected = '---'
        expect(result).to eq(expected)
      end
    end

    context 'with image blocks' do
      let(:blocks) do
        [
          {
            'type' => 'image',
            'image' => {
              'type' => 'external',
              'external' => {
                'url' => 'https://example.com/image.jpg'
              },
              'caption' => [
                { 'plain_text' => 'Example image' }
              ]
            }
          }
        ]
      end

      it 'converts images to markdown' do
        result = converter.convert(blocks)
        expected = '![Example image](https://example.com/image.jpg)'
        expect(result).to eq(expected)
      end
    end

    context 'with bookmark blocks' do
      let(:blocks) do
        [
          {
            'type' => 'bookmark',
            'bookmark' => {
              'url' => 'https://example.com'
            }
          }
        ]
      end

      it 'converts bookmarks to markdown' do
        result = converter.convert(blocks)
        expected = '[https://example.com](https://example.com)'
        expect(result).to eq(expected)
      end
    end

    context 'with table blocks' do
      let(:blocks) do
        [
          {
            'type' => 'table',
            'table' => {},
            'children' => [
              {
                'type' => 'table_row',
                'table_row' => {
                  'cells' => [
                    [{ 'plain_text' => 'Name' }],
                    [{ 'plain_text' => 'Age' }]
                  ]
                }
              },
              {
                'type' => 'table_row',
                'table_row' => {
                  'cells' => [
                    [{ 'plain_text' => 'John' }],
                    [{ 'plain_text' => '30' }]
                  ]
                }
              }
            ]
          }
        ]
      end

      it 'converts tables to markdown' do
        result = converter.convert(blocks)
        expected = "| Name | Age |\n| --- | --- |\n| John | 30 |"
        expect(result).to eq(expected)
      end
    end

    context 'with nested list items' do
      let(:blocks) do
        [
          {
            'type' => 'bulleted_list_item',
            'bulleted_list_item' => {
              'rich_text' => [{ 'plain_text' => 'Parent item' }]
            },
            'has_children' => true,
            'children' => [
              {
                'type' => 'bulleted_list_item',
                'bulleted_list_item' => {
                  'rich_text' => [{ 'plain_text' => 'Child item' }]
                }
              }
            ]
          }
        ]
      end

      it 'handles nested lists with proper indentation' do
        result = converter.convert(blocks)
        expected = "- Parent item\n  - Child item"
        expect(result).to eq(expected)
      end
    end

    context 'with toggle blocks' do
      let(:blocks) do
        [
          {
            'type' => 'toggle',
            'toggle' => {
              'rich_text' => [{ 'plain_text' => 'Click to expand' }]
            },
            'has_children' => true,
            'children' => [
              {
                'type' => 'paragraph',
                'paragraph' => {
                  'rich_text' => [{ 'plain_text' => 'Hidden content' }]
                }
              }
            ]
          }
        ]
      end

      it 'converts toggles to HTML details' do
        result = converter.convert(blocks)
        expected = "<details>\n<summary>Click to expand</summary>\n\n\nHidden content\n</details>"
        expect(result).to eq(expected)
      end
    end

    context 'with unknown block types' do
      let(:blocks) do
        [
          {
            'type' => 'unknown_block_type',
            'unknown_block_type' => {
              'content' => 'Some content'
            }
          }
        ]
      end

      it 'ignores unknown block types' do
        result = converter.convert(blocks)
        expect(result).to eq('')
      end
    end

    context 'with empty blocks array' do
      let(:blocks) { [] }

      it 'returns empty string' do
        result = converter.convert(blocks)
        expect(result).to eq('')
      end
    end
  end
end