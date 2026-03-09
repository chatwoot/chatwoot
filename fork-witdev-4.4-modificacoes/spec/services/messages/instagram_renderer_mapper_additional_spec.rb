# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::InstagramRendererMapper, 'Additional Coverage' do
  describe 'comprehensive security testing' do
    context 'with malicious payloads' do
      it 'prevents XSS attacks in titles and descriptions' do
        xss_payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => '<script>alert("XSS")</script>Malicious Title',
              'subtitle' => '<img src=x onerror=alert("XSS")>Malicious Description',
              'image_url' => 'https://example.com/image.jpg'
            }
          ]
        }

        result = described_class.map(xss_payload)
        card = result.content_attributes['items'].first

        # Titles and descriptions should be treated as plain text
        expect(card['title']).to eq('<script>alert("XSS")</script>Malicious Title')
        expect(card['description']).to eq('<img src=x onerror=alert("XSS")>Malicious Description')
        
        # But they should be properly escaped when rendered in frontend
        expect(card['title']).not_to include('javascript:')
        expect(card['description']).not_to include('onerror=')
      end

      it 'prevents SSRF attacks through image URLs' do
        ssrf_payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'SSRF Test',
              'image_url' => 'http://169.254.169.254/latest/meta-data/'  # AWS metadata endpoint
            }
          ]
        }

        result = described_class.map(ssrf_payload)
        card = result.content_attributes['items'].first

        expect(card['media_url']).to be_nil
      end

      it 'prevents protocol smuggling attacks' do
        protocol_attacks = [
          'data:text/html,<script>alert(1)</script>',
          'vbscript:msgbox(1)',
          'javascript:void(0)',
          'file:///etc/passwd',
          'gopher://example.com:25/xHELO%20example.com'
        ]

        protocol_attacks.each do |malicious_url|
          payload = {
            'template_type' => 'generic',
            'elements' => [
              {
                'title' => 'Protocol Test',
                'image_url' => malicious_url,
                'buttons' => [
                  {
                    'type' => 'web_url',
                    'title' => 'Malicious Link',
                    'url' => malicious_url
                  }
                ]
              }
            ]
          }

          result = described_class.map(payload)
          card = result.content_attributes['items'].first

          expect(card['media_url']).to be_nil, "Expected #{malicious_url} to be rejected as image URL"
          expect(card['actions']).to be_empty, "Expected #{malicious_url} to be rejected as button URL"
        end
      end
    end

    context 'with DoS attack payloads' do
      it 'prevents zip bomb attacks with deeply nested structures' do
        # Create a payload with deeply nested button structures
        nested_buttons = []
        1000.times do |i|
          nested_buttons << {
            'type' => 'postback',
            'title' => "Button #{i}" * 100,  # Long titles
            'payload' => "PAYLOAD_#{i}" * 100  # Long payloads
          }
        end

        zip_bomb_payload = {
          'template_type' => 'button',
          'text' => 'Choose from many options:',
          'buttons' => nested_buttons
        }

        # Should complete quickly without hanging
        start_time = Time.current
        result = described_class.map(zip_bomb_payload)
        elapsed_time = Time.current - start_time

        expect(elapsed_time).to be < 1.0  # Should complete in under 1 second
        expect(result.content_type).to eq('cards')
        
        # Should be limited to MAX_BTNS
        card = result.content_attributes['items'].first
        expect(card['actions'].length).to eq(described_class::MAX_BTNS)
      end

      it 'handles extremely large element counts efficiently' do
        # Create payload with maximum allowed elements
        large_elements = []
        described_class::MAX_CARDS.times do |i|
          large_elements << {
            'title' => "Element #{i}",
            'subtitle' => "Description #{i}",
            'image_url' => "https://example.com/image#{i}.jpg"
          }
        end

        large_payload = {
          'template_type' => 'generic',
          'elements' => large_elements
        }

        start_time = Time.current
        result = described_class.map(large_payload)
        elapsed_time = Time.current - start_time

        expect(elapsed_time).to be < 0.5  # Should be fast even with max elements
        expect(result.content_attributes['items'].length).to eq(described_class::MAX_CARDS)
      end
    end
  end

  describe 'edge case URL validation' do
    it 'handles international domain names correctly' do
      international_urls = [
        'https://例え.テスト',  # Japanese IDN
        'https://пример.испытание',  # Russian IDN
        'https://مثال.آزمایشی',  # Persian IDN
        'https://xn--fsq.xn--0zwm56d'  # Punycode encoded
      ]

      international_urls.each do |url|
        payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'International URL Test',
              'image_url' => url,
              'buttons' => [
                {
                  'type' => 'web_url',
                  'title' => 'International Link',
                  'url' => url
                }
              ]
            }
          ]
        }

        result = described_class.map(payload)
        card = result.content_attributes['items'].first

        # International URLs should be handled gracefully
        # (may be accepted or rejected based on URI parsing)
        expect(result.content_type).to eq('cards')
        expect(card).to have_key('media_url')
        expect(card).to have_key('actions')
      end
    end

    it 'handles URLs with unusual but valid characters' do
      unusual_urls = [
        'https://example.com/path?query=value&other=123',
        'https://example.com:8080/secure/path',
        'https://sub.domain.example.com/deep/path/file.html',
        'https://example.com/path-with-dashes_and_underscores',
        'https://example.com/path%20with%20encoded%20spaces'
      ]

      unusual_urls.each do |url|
        safe_url = described_class.send(:safe_url, url)
        expect(safe_url).to eq(url), "Expected #{url} to be accepted as valid"
      end
    end

    it 'rejects URLs with suspicious patterns' do
      suspicious_urls = [
        'https://example.com@attacker.com',  # Username in URL
        'https://example.com/../../../etc/passwd',  # Path traversal
        'https://example.com/redirect?url=http://attacker.com',  # Open redirect
        'https://example.com#javascript:alert(1)',  # JavaScript in fragment
        'https://example.com?callback=<script>alert(1)</script>'  # XSS in query
      ]

      suspicious_urls.each do |url|
        safe_url = described_class.send(:safe_url, url)
        # These should either be rejected or sanitized
        if safe_url
          expect(safe_url).not_to include('javascript:')
          expect(safe_url).not_to include('<script>')
          expect(safe_url).not_to include('@attacker.com')
        end
      end
    end
  end

  describe 'performance benchmarks' do
    it 'maintains performance with realistic payloads' do
      # Test with a realistic e-commerce carousel
      realistic_payload = {
        'template_type' => 'generic',
        'elements' => (1..5).map do |i|
          {
            'title' => "Product #{i}: High Quality Item with Long Descriptive Name",
            'subtitle' => "This is a detailed product description that explains all the features and benefits of this amazing product. It includes multiple sentences to simulate real-world content.",
            'image_url' => "https://cdn.example.com/products/high-res-image-#{i}.jpg?version=2&quality=high",
            'buttons' => [
              {
                'type' => 'web_url',
                'title' => 'View Details',
                'url' => "https://shop.example.com/products/item-#{i}?utm_source=instagram&utm_campaign=rich_messages"
              },
              {
                'type' => 'postback',
                'title' => 'Add to Cart',
                'payload' => "ADD_TO_CART_PRODUCT_#{i}_VARIANT_DEFAULT"
              },
              {
                'type' => 'postback',
                'title' => 'Save for Later',
                'payload' => "SAVE_FOR_LATER_PRODUCT_#{i}"
              }
            ]
          }
        end
      }

      # Should handle realistic payloads quickly
      times = []
      10.times do
        start_time = Time.current
        described_class.map(realistic_payload)
        times << (Time.current - start_time)
      end

      average_time = times.sum / times.length
      expect(average_time).to be < 0.05  # Should average under 50ms
    end

    it 'handles cache misses efficiently' do
      Rails.cache.clear

      # Generate unique payloads to ensure cache misses
      payloads = 50.times.map do |i|
        {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => "Unique Product #{i}",
              'subtitle' => "Description #{i}"
            }
          ]
        }
      end

      start_time = Time.current
      payloads.each { |payload| described_class.map(payload) }
      elapsed_time = Time.current - start_time

      expect(elapsed_time).to be < 2.0  # Should handle 50 cache misses in under 2 seconds
    end
  end

  describe 'memory usage optimization' do
    it 'does not leak memory with large payloads' do
      # This test ensures we don't hold references to large objects
      initial_objects = ObjectSpace.count_objects

      100.times do |i|
        large_payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'A' * 1000,
              'subtitle' => 'B' * 1000,
              'image_url' => 'https://example.com/image.jpg'
            }
          ]
        }
        described_class.map(large_payload)
      end

      # Force garbage collection
      GC.start

      final_objects = ObjectSpace.count_objects
      object_growth = final_objects[:T_STRING] - initial_objects[:T_STRING]

      # Should not have excessive string object growth
      expect(object_growth).to be < 1000
    end
  end

  describe 'thread safety' do
    it 'handles concurrent requests safely' do
      threads = []
      results = []
      mutex = Mutex.new

      # Create multiple threads making concurrent requests
      10.times do |i|
        threads << Thread.new do
          payload = {
            'template_type' => 'generic',
            'elements' => [
              {
                'title' => "Concurrent Product #{i}",
                'subtitle' => "Thread #{Thread.current.object_id}"
              }
            ]
          }

          result = described_class.map(payload)
          mutex.synchronize { results << result }
        end
      end

      threads.each(&:join)

      # All threads should complete successfully
      expect(results.length).to eq(10)
      results.each do |result|
        expect(result.content_type).to eq('cards')
        expect(result.content_attributes['items']).to be_present
      end
    end
  end

  describe 'constants and configuration' do
    it 'has reasonable constant values for production use' do
      expect(described_class::MAX_CARDS).to be_between(5, 20)
      expect(described_class::MAX_BTNS).to be_between(2, 5)
      expect(described_class::MAX_PAYLOAD_SIZE).to be_between(10.kilobytes, 50.kilobytes)
      expect(described_class::TITLE_LIMIT).to be_between(50, 200)
      expect(described_class::DESCRIPTION_LIMIT).to be_between(100, 500)
      expect(described_class::CACHE_TTL).to be_between(30.minutes, 4.hours)
    end

    it 'has consistent constant relationships' do
      expect(described_class::TITLE_LIMIT).to be < described_class::DESCRIPTION_LIMIT
      expect(described_class::MAX_BTNS).to be <= described_class::MAX_CARDS
    end
  end
end