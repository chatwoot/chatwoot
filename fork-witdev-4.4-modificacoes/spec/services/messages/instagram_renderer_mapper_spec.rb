# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::InstagramRendererMapper do
  describe '.map' do
    context 'with Generic Template payload' do
      let(:generic_payload) do
        {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Product 1',
              'subtitle' => 'Amazing product description',
              'image_url' => 'https://example.com/image1.jpg',
              'buttons' => [
                {
                  'type' => 'web_url',
                  'title' => 'View More',
                  'url' => 'https://example.com/product1'
                },
                {
                  'type' => 'postback',
                  'title' => 'Buy Now',
                  'payload' => 'BUY_PRODUCT_1'
                }
              ]
            },
            {
              'title' => 'Product 2',
              'subtitle' => 'Another great product',
              'image_url' => 'https://example.com/image2.jpg',
              'buttons' => [
                {
                  'type' => 'postback',
                  'title' => 'Select',
                  'payload' => 'SELECT_PRODUCT_2'
                }
              ]
            }
          ]
        }
      end

      it 'converts to cards structure' do
        result = described_class.map(generic_payload)

        expect(result.content_type).to eq('cards')
        expect(result.content_attributes['items']).to be_an(Array)
        expect(result.content_attributes['items'].length).to eq(2)
        expect(result.fallback_text).to eq('Product 1 — Amazing product description')
      end

      it 'maps card items correctly' do
        result = described_class.map(generic_payload)
        first_card = result.content_attributes['items'].first

        expect(first_card['title']).to eq('Product 1')
        expect(first_card['description']).to eq('Amazing product description')
        expect(first_card['media_url']).to eq('https://example.com/image1.jpg')
        expect(first_card['actions']).to be_an(Array)
        expect(first_card['actions'].length).to eq(2)
      end

      it 'maps buttons to actions correctly' do
        result = described_class.map(generic_payload)
        actions = result.content_attributes['items'].first['actions']

        web_url_action = actions.find { |a| a['type'] == 'link' }
        expect(web_url_action['text']).to eq('View More')
        expect(web_url_action['uri']).to eq('https://example.com/product1')

        postback_action = actions.find { |a| a['type'] == 'postback' }
        expect(postback_action['text']).to eq('Buy Now')
        expect(postback_action['payload']).to eq('BUY_PRODUCT_1')
      end

      it 'limits cards to MAX_CARDS' do
        # Create payload with more than MAX_CARDS elements
        elements = (1..15).map do |i|
          {
            'title' => "Product #{i}",
            'subtitle' => "Description #{i}"
          }
        end
        payload = { 'template_type' => 'generic', 'elements' => elements }

        result = described_class.map(payload)
        expect(result.content_attributes['items'].length).to eq(described_class::MAX_CARDS)
      end

      it 'truncates long titles and descriptions' do
        long_title = 'A' * 200
        long_description = 'B' * 300
        payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => long_title,
              'subtitle' => long_description
            }
          ]
        }

        result = described_class.map(payload)
        card = result.content_attributes['items'].first

        expect(card['title'].length).to be <= described_class::TITLE_LIMIT
        expect(card['description'].length).to be <= described_class::DESCRIPTION_LIMIT
      end
    end

    context 'with Button Template payload' do
      let(:button_payload) do
        {
          'template_type' => 'button',
          'text' => 'Choose an option:',
          'buttons' => [
            {
              'type' => 'postback',
              'title' => 'Yes',
              'payload' => 'YES'
            },
            {
              'type' => 'postback',
              'title' => 'No',
              'payload' => 'NO'
            },
            {
              'type' => 'web_url',
              'title' => 'Learn More',
              'url' => 'https://example.com/info'
            }
          ]
        }
      end

      it 'converts to single card structure' do
        result = described_class.map(button_payload)

        expect(result.content_type).to eq('cards')
        expect(result.content_attributes['items']).to be_an(Array)
        expect(result.content_attributes['items'].length).to eq(1)
        expect(result.fallback_text).to eq('Choose an option:')
      end

      it 'maps button template correctly (text as body without truncation)' do
        result = described_class.map(button_payload)
        card = result.content_attributes['items'].first

        expect(card['body']).to eq('Choose an option:')
        expect(card['actions']).to be_an(Array)
        expect(card['actions'].length).to eq(3)
      end

      it 'limits buttons to MAX_BTNS' do
        # Create payload with more than MAX_BTNS buttons
        buttons = (1..5).map do |i|
          {
            'type' => 'postback',
            'title' => "Option #{i}",
            'payload' => "OPTION_#{i}"
          }
        end
        payload = {
          'template_type' => 'button',
          'text' => 'Choose:',
          'buttons' => buttons
        }

        result = described_class.map(payload)
        card = result.content_attributes['items'].first
        expect(card['actions'].length).to eq(described_class::MAX_BTNS)
      end
    end

    context 'with Quick Replies payload' do
      let(:quick_replies_payload) do
        {
          'text' => 'What would you like to do?',
          'quick_replies' => [
            {
              'content_type' => 'text',
              'title' => 'Option 1',
              'payload' => 'OPTION_1'
            },
            {
              'content_type' => 'text',
              'title' => 'Option 2',
              'payload' => 'OPTION_2'
            },
            {
              'content_type' => 'text',
              'title' => 'Option 3',
              'payload' => 'OPTION_3'
            }
          ]
        }
      end

      it 'converts to input_select structure' do
        result = described_class.map(quick_replies_payload)

        expect(result.content_type).to eq('input_select')
        expect(result.content_attributes['items']).to be_an(Array)
        expect(result.content_attributes['items'].length).to eq(3)
        expect(result.fallback_text).to eq('What would you like to do? (3 options)')
      end

      it 'maps quick reply items correctly' do
        result = described_class.map(quick_replies_payload)
        items = result.content_attributes['items']

        expect(items.first['title']).to eq('Option 1')
        expect(items.first['value']).to eq('OPTION_1')
        expect(items.last['title']).to eq('Option 3')
        expect(items.last['value']).to eq('OPTION_3')
      end

      it 'skips quick replies with missing title or payload' do
        payload = {
          'text' => 'Choose:',
          'quick_replies' => [
            {
              'content_type' => 'text',
              'title' => 'Valid Option',
              'payload' => 'VALID'
            },
            {
              'content_type' => 'text',
              'title' => '',
              'payload' => 'INVALID_TITLE'
            },
            {
              'content_type' => 'text',
              'title' => 'Invalid Payload',
              'payload' => ''
            }
          ]
        }

        result = described_class.map(payload)
        expect(result.content_attributes['items'].length).to eq(1)
        expect(result.content_attributes['items'].first['title']).to eq('Valid Option')
      end
    end

    context 'with URL sanitization' do
      let(:payload_with_urls) do
        {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Test Card',
              'image_url' => 'https://example.com/valid.jpg',
              'buttons' => [
                {
                  'type' => 'web_url',
                  'title' => 'Valid URL',
                  'url' => 'https://example.com/valid'
                },
                {
                  'type' => 'web_url',
                  'title' => 'Invalid URL',
                  'url' => 'not-a-url'
                },
                {
                  'type' => 'web_url',
                  'title' => 'Localhost URL',
                  'url' => 'http://localhost:3000/test'
                }
              ]
            }
          ]
        }
      end

      it 'sanitizes URLs correctly' do
        result = described_class.map(payload_with_urls)
        card = result.content_attributes['items'].first

        expect(card['media_url']).to eq('https://example.com/valid.jpg')

        # Should only have the valid URL button
        valid_actions = card['actions'].select { |a| a['type'] == 'link' }
        expect(valid_actions.length).to eq(1)
        expect(valid_actions.first['uri']).to eq('https://example.com/valid')
      end

      it 'rejects invalid URLs' do
        invalid_urls = [
          'not-a-url',
          'ftp://example.com/file',
          'javascript:alert(1)',
          'http://localhost:3000',
          'https://127.0.0.1:8080',
          ''
        ]

        invalid_urls.each do |url|
          safe_url = described_class.send(:safe_url, url)
          expect(safe_url).to be_nil, "Expected #{url} to be rejected"
        end
      end

      it 'accepts valid URLs' do
        valid_urls = [
          'https://example.com',
          'http://example.com/path',
          'https://subdomain.example.com/path?query=1',
          'https://example.com:8080/secure'
        ]

        valid_urls.each do |url|
          safe_url = described_class.send(:safe_url, url)
          expect(safe_url).to eq(url), "Expected #{url} to be accepted"
        end
      end
    end

    context 'with payload size validation' do
      it 'rejects oversized payloads' do
        # Create a large payload that exceeds MAX_PAYLOAD_SIZE
        large_elements = (1..100).map do |_i|
          {
            'title' => 'A' * 1000,
            'subtitle' => 'B' * 1000,
            'image_url' => 'https://example.com/image.jpg',
            'buttons' => [
              {
                'type' => 'postback',
                'title' => 'Button',
                'payload' => 'C' * 1000
              }
            ]
          }
        end

        large_payload = {
          'template_type' => 'generic',
          'elements' => large_elements
        }

        result = described_class.map(large_payload)
        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('Rich message')
      end

      it 'accepts normal sized payloads' do
        normal_payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Normal Title',
              'subtitle' => 'Normal description'
            }
          ]
        }

        result = described_class.map(normal_payload)
        expect(result.content_type).to eq('cards')
      end
    end

    context 'with invalid payloads' do
      it 'handles nil payload' do
        result = described_class.map(nil)
        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('Rich message')
      end

      it 'handles empty payload' do
        result = described_class.map({})
        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('Rich message')
      end

      it 'handles non-hash payload' do
        result = described_class.map('invalid')
        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('Rich message')
      end

      it 'handles unknown template type' do
        payload = {
          'template_type' => 'unknown',
          'text' => 'Some text content'
        }

        result = described_class.map(payload)
        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('Some text content')
      end

      it 'handles generic template with empty elements' do
        payload = {
          'template_type' => 'generic',
          'elements' => []
        }

        result = described_class.map(payload)
        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('Rich message')
      end

      it 'handles button template with no text or buttons' do
        payload = {
          'template_type' => 'button'
        }

        result = described_class.map(payload)
        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('Rich message')
      end

      it 'handles quick replies with empty array' do
        payload = {
          'text' => 'Choose:',
          'quick_replies' => []
        }

        result = described_class.map(payload)
        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('Choose:')
      end
    end

    context 'with caching' do
      let(:test_payload) do
        {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Test Product',
              'subtitle' => 'Test Description'
            }
          ]
        }
      end

      it 'caches results based on payload hash' do
        # Clear any existing cache
        Rails.cache.clear

        # First call should hit the mapper
        expect(described_class).to receive(:map_payload).once.and_call_original
        result1 = described_class.map(test_payload)

        # Second call should use cache
        expect(described_class).not_to receive(:map_payload)
        result2 = described_class.map(test_payload)

        expect(result1.content_type).to eq(result2.content_type)
        expect(result1.content_attributes).to eq(result2.content_attributes)
      end

      it 'generates different cache keys for different payloads' do
        payload1 = { 'template_type' => 'generic', 'elements' => [{ 'title' => 'A' }] }
        payload2 = { 'template_type' => 'generic', 'elements' => [{ 'title' => 'B' }] }

        key1 = described_class.send(:generate_cache_key, payload1)
        key2 = described_class.send(:generate_cache_key, payload2)

        expect(key1).not_to eq(key2)
        expect(key1).to start_with('instagram_mapper:')
        expect(key2).to start_with('instagram_mapper:')
      end
    end

    context 'with error handling' do
      it 'handles mapping errors gracefully' do
        # Mock an error during mapping
        allow(described_class).to receive(:map_payload).and_raise(StandardError, 'Test error')

        payload = {
          'template_type' => 'generic',
          'elements' => [{ 'title' => 'Test' }]
        }

        result = described_class.map(payload)
        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('Rich message')
      end

      it 'logs mapping errors' do
        allow(described_class).to receive(:map_payload).and_raise(StandardError, 'Test error')
        allow(Rails.logger).to receive(:error)

        payload = { 'template_type' => 'generic', 'elements' => [{ 'title' => 'Test' }] }
        described_class.map(payload)

        expect(Rails.logger).to have_received(:error).with(
          '[INSTAGRAM-MAPPER] Mapping failed: StandardError: Test error'
        )
      end
    end

    context 'with text extraction' do
      it 'extracts text from various payload formats' do
        # Text from direct text field
        payload1 = { 'text' => 'Direct text' }
        result1 = described_class.send(:extract_text_from_payload, payload1)
        expect(result1).to eq('Direct text')

        # Text from first element title
        payload2 = { 'elements' => [{ 'title' => 'Element title' }] }
        result2 = described_class.send(:extract_text_from_payload, payload2)
        expect(result2).to eq('Element title')

        # Text from first quick reply title
        payload3 = { 'quick_replies' => [{ 'title' => 'Quick reply title' }] }
        result3 = described_class.send(:extract_text_from_payload, payload3)
        expect(result3).to eq('Quick reply title')

        # Default fallback
        payload4 = {}
        result4 = described_class.send(:extract_text_from_payload, payload4)
        expect(result4).to eq('Rich message')
      end

      it 'truncates long text' do
        long_text = 'A' * 600
        payload = { 'text' => long_text }
        result = described_class.send(:extract_text_from_payload, payload)
        expect(result.length).to be <= 500
      end
    end
  end
end
