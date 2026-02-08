# frozen_string_literal: true

require 'rails_helper'
require_relative '../../fixtures/instagram_rich_payloads'

RSpec.describe Messages::InstagramRendererMapper, 'Integration Tests' do
  include InstagramRichPayloads

  describe 'requirement validation' do
    context 'Generic Template to cards conversion (Req 2.1)' do
      it 'converts generic template with title/description truncation' do
        result = described_class.map(GENERIC_TEMPLATE_PAYLOAD)

        expect(result.content_type).to eq('cards')
        expect(result.content_attributes['items']).to be_an(Array)
        expect(result.content_attributes['items'].length).to eq(2)

        first_card = result.content_attributes['items'].first
        expect(first_card['title']).to eq('Product 1')
        expect(first_card['description']).to eq('Amazing product description')
        expect(first_card['media_url']).to eq('https://example.com/image1.jpg')
        expect(first_card['actions']).to be_an(Array)
      end

      it 'truncates long titles and descriptions' do
        result = described_class.map(LONG_TEXT_PAYLOAD)
        card = result.content_attributes['items'].first

        expect(card['title'].length).to be <= described_class::TITLE_LIMIT
        expect(card['description'].length).to be <= described_class::DESCRIPTION_LIMIT
      end
    end

    context 'Button Template to single card conversion (Req 2.2)' do
      it 'converts button template to single card with text as body' do
        result = described_class.map(BUTTON_TEMPLATE_PAYLOAD)

        expect(result.content_type).to eq('cards')
        expect(result.content_attributes['items'].length).to eq(1)

        card = result.content_attributes['items'].first
        expect(card['body']).to eq('Choose an option:')
        expect(card['actions'].length).to eq(3)
      end
    end

    context 'Quick Replies to input_select conversion (Req 2.3)' do
      it 'converts quick replies to input_select' do
        result = described_class.map(QUICK_REPLIES_PAYLOAD)

        expect(result.content_type).to eq('input_select')
        expect(result.content_attributes['items']).to be_an(Array)
        expect(result.content_attributes['items'].length).to eq(3)

        first_item = result.content_attributes['items'].first
        expect(first_item['title']).to eq('Option 1')
        expect(first_item['value']).to eq('OPTION_1')
      end
    end

    context 'URL sanitization and validation (Req 2.4, 6.1)' do
      it 'sanitizes and validates URLs for security' do
        result = described_class.map(INVALID_URLS_PAYLOAD)
        card = result.content_attributes['items'].first

        # Should reject invalid URLs
        expect(card['media_url']).to be_nil  # JavaScript URL rejected

        # Should only keep valid URL buttons
        valid_actions = card['actions'].select { |a| a['type'] == 'link' }
        expect(valid_actions.length).to eq(1)
        expect(valid_actions.first['uri']).to eq('https://example.com/safe')
      end

      it 'rejects dangerous URLs' do
        dangerous_urls = [
          'javascript:alert(1)',
          'http://localhost:3000',
          'https://127.0.0.1:8080',
          'ftp://example.com/file'
        ]

        dangerous_urls.each do |url|
          safe_url = described_class.send(:safe_url, url)
          expect(safe_url).to be_nil, "Expected #{url} to be rejected"
        end
      end
    end

    context 'Element and button count limits (Req 2.5, 2.6)' do
      it 'limits cards to MAX_CARDS (50 max)' do
        result = described_class.map(EXCESSIVE_ELEMENTS_PAYLOAD)
        expect(result.content_attributes['items'].length).to eq(described_class::MAX_CARDS)
      end

      it 'limits buttons to MAX_BTNS (3 max)' do
        result = described_class.map(EXCESSIVE_BUTTONS_PAYLOAD)
        card = result.content_attributes['items'].first
        expect(card['actions'].length).to eq(described_class::MAX_BTNS)
      end
    end

    context 'Payload size validation (25KB limit) (Req 6.3)' do
      it 'rejects oversized payloads' do
        result = described_class.map(OVERSIZED_PAYLOAD)
        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('Rich message')
      end

      it 'validates payload size correctly' do
        payload_size = OVERSIZED_PAYLOAD.to_json.bytesize
        expect(payload_size).to be > described_class::MAX_PAYLOAD_SIZE
      end
    end

    context 'Cache mechanism with MD5 hash keys and 1-hour TTL (Req 6.1)' do
      it 'caches results with MD5 hash keys' do
        Rails.cache.clear

        # Mock cache to verify TTL
        expect(Rails.cache).to receive(:fetch)
          .with(start_with('instagram_mapper:'), expires_in: described_class::CACHE_TTL)
          .and_call_original

        described_class.map(GENERIC_TEMPLATE_PAYLOAD)
      end

      it 'generates consistent cache keys for same payload' do
        key1 = described_class.send(:generate_cache_key, GENERIC_TEMPLATE_PAYLOAD)
        key2 = described_class.send(:generate_cache_key, GENERIC_TEMPLATE_PAYLOAD)

        expect(key1).to eq(key2)
        expect(key1).to start_with('instagram_mapper:')
        expect(key1.length).to eq('instagram_mapper:'.length + 32) # MD5 hash length
      end

      it 'uses cache for identical payloads' do
        Rails.cache.clear

        # First call should hit the mapper
        expect(described_class).to receive(:map_payload).once.and_call_original
        result1 = described_class.map(GENERIC_TEMPLATE_PAYLOAD)

        # Second call should use cache
        expect(described_class).not_to receive(:map_payload)
        result2 = described_class.map(GENERIC_TEMPLATE_PAYLOAD)

        expect(result1.content_type).to eq(result2.content_type)
      end
    end

    context 'Error handling and fallbacks (Req 6.3)' do
      it 'handles invalid payloads gracefully' do
        MALFORMED_PAYLOADS.each do |invalid_payload|
          result = described_class.map(invalid_payload)
          expect(result.content_type).to eq('text')
          expect(result.fallback_text).to be_a(String)
        end
      end

      it 'handles mapping errors gracefully' do
        allow(described_class).to receive(:map_payload).and_raise(StandardError, 'Test error')

        result = described_class.map(GENERIC_TEMPLATE_PAYLOAD)
        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('Rich message')
      end

      it 'logs mapping errors' do
        allow(described_class).to receive(:map_payload).and_raise(StandardError, 'Test error')
        allow(Rails.logger).to receive(:error)

        described_class.map(GENERIC_TEMPLATE_PAYLOAD)

        expect(Rails.logger).to have_received(:error).with(
          '[INSTAGRAM-MAPPER] Mapping failed: StandardError: Test error'
        )
      end
    end

    context 'Edge cases and robustness' do
      it 'handles edge case payloads correctly' do
        EDGE_CASE_PAYLOADS.each do |_name, payload|
          result = described_class.map(payload)
          expect(result).to be_a(described_class::Mapped)
          expect(result.content_type).to be_a(String)
          expect(result.content_attributes).to be_a(Hash)
          expect(result.fallback_text).to be_a(String)
        end
      end

      it 'handles unicode and special characters' do
        result = described_class.map(EDGE_CASE_PAYLOADS[:unicode_payload])
        card = result.content_attributes['items'].first

        expect(card['title']).to include('🎉')
        expect(card['title']).to include('特別な製品')
        expect(card['description']).to include('émojis')
        expect(card['description']).to include('àccénts')
      end

      it 'filters out invalid buttons while keeping valid ones' do
        result = described_class.map(EDGE_CASE_PAYLOADS[:mixed_buttons])
        card = result.content_attributes['items'].first

        # Should have 2 valid actions (1 postback + 1 web_url)
        expect(card['actions'].length).to eq(2)

        postback_action = card['actions'].find { |a| a['type'] == 'postback' }
        expect(postback_action['text']).to eq('Valid Postback')

        link_action = card['actions'].find { |a| a['type'] == 'link' }
        expect(link_action['text']).to eq('Valid URL')
      end
    end

    context 'Performance and security' do
      it 'has reasonable performance for normal payloads' do
        start_time = Time.now

        100.times do
          described_class.map(GENERIC_TEMPLATE_PAYLOAD)
        end

        elapsed_time = Time.now - start_time
        expect(elapsed_time).to be < 1.0 # Should complete 100 mappings in under 1 second
      end

      it 'prevents DoS attacks with element limits' do
        # Test with maximum allowed elements
        max_elements = (1..described_class::MAX_CARDS).map do |i|
          { 'title' => "Element #{i}" }
        end

        payload = {
          'template_type' => 'generic',
          'elements' => max_elements
        }

        result = described_class.map(payload)
        expect(result.content_attributes['items'].length).to eq(described_class::MAX_CARDS)
      end

      it 'prevents DoS attacks with button limits' do
        # Test with maximum allowed buttons
        max_buttons = (1..described_class::MAX_BTNS).map do |i|
          {
            'type' => 'postback',
            'title' => "Button #{i}",
            'payload' => "PAYLOAD_#{i}"
          }
        end

        payload = {
          'template_type' => 'button',
          'text' => 'Choose:',
          'buttons' => max_buttons
        }

        result = described_class.map(payload)
        card = result.content_attributes['items'].first
        expect(card['actions'].length).to eq(described_class::MAX_BTNS)
      end
    end
  end

  describe 'constants validation' do
    it 'has correct constant values' do
      expect(described_class::MAX_CARDS).to eq(10)
      expect(described_class::MAX_BTNS).to eq(3)
      expect(described_class::MAX_PAYLOAD_SIZE).to eq(25.kilobytes)
      expect(described_class::TITLE_LIMIT).to eq(120)
      expect(described_class::DESCRIPTION_LIMIT).to eq(200)
      expect(described_class::CACHE_TTL).to eq(1.hour)
    end
  end

  describe 'Mapped struct' do
    it 'creates proper Mapped instances' do
      mapped = described_class::Mapped.new('cards', { 'items' => [] }, 'fallback')

      expect(mapped.content_type).to eq('cards')
      expect(mapped.content_attributes).to eq({ 'items' => [] })
      expect(mapped.fallback_text).to eq('fallback')
    end
  end
end
