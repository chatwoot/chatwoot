# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::WhatsappRendererMapper do
  describe '.map' do
    context 'with button template payload' do
      let(:button_payload) do
        {
          'type' => 'button',
          'body' => {
            'text' => 'Sr(a) Cliente, Somos especializados em mandado de segurança'
          },
          'header' => {
            'type' => 'image',
            'image' => {
              'link' => 'https://example.com/image.png'
            }
          },
          'footer' => {
            'text' => 'Dra. Amanda Sousa Advocacia e Consultoria Jurídica™'
          },
          'action' => {
            'buttons' => [
              {
                'type' => 'reply',
                'reply' => {
                  'id' => 'btn_1756139209769_0_u8bq',
                  'title' => 'Falar com a Dra'
                }
              }
            ]
          }
        }
      end

      it 'converts to cards format' do
        result = described_class.map(button_payload)

        expect(result.content_type).to eq('cards')
        expect(result.content_attributes['items']).to be_an(Array)
        expect(result.content_attributes['items'].length).to eq(1)
      end

      it 'maps button content correctly' do
        result = described_class.map(button_payload)
        card = result.content_attributes['items'].first

        expect(card['title']).to eq('Sr(a) Cliente, Somos especializados em mandado de segurança')
        expect(card['description']).to eq('Dra. Amanda Sousa Advocacia e Consultoria Jurídica™')
        expect(card['media_url']).to eq('https://example.com/image.png')
        expect(card['actions']).to be_an(Array)
        expect(card['actions'].length).to eq(1)
      end

      it 'maps button actions correctly' do
        result = described_class.map(button_payload)
        action = result.content_attributes['items'].first['actions'].first

        expect(action['type']).to eq('postback')
        expect(action['text']).to eq('Falar com a Dra')
        expect(action['payload']).to eq('btn_1756139209769_0_u8bq')
      end

      it 'generates appropriate fallback text' do
        result = described_class.map(button_payload)

        expect(result.fallback_text).to include('Sr(a) Cliente')
        expect(result.fallback_text).to include('Dra. Amanda Sousa')
        expect(result.fallback_text).to include('Falar com a Dra')
      end
    end

    context 'with list template payload' do
      let(:list_payload) do
        {
          'type' => 'list',
          'body' => {
            'text' => 'Escolha uma opção:'
          },
          'action' => {
            'button' => 'Ver opções',
            'sections' => [
              {
                'title' => 'Serviços',
                'rows' => [
                  {
                    'id' => 'option_1',
                    'title' => 'Consultoria Jurídica',
                    'description' => 'Orientação jurídica especializada'
                  },
                  {
                    'id' => 'option_2',
                    'title' => 'Mandado de Segurança',
                    'description' => 'Proteção de direitos líquidos e certos'
                  }
                ]
              }
            ]
          }
        }
      end

      it 'converts to input_select format' do
        result = described_class.map(list_payload)

        expect(result.content_type).to eq('input_select')
        expect(result.content_attributes['items']).to be_an(Array)
        expect(result.content_attributes['items'].length).to eq(2)
      end

      it 'maps list options correctly' do
        result = described_class.map(list_payload)
        items = result.content_attributes['items']

        expect(items[0]['title']).to eq('Consultoria Jurídica')
        expect(items[0]['value']).to eq('option_1')
        expect(items[0]['description']).to eq('Orientação jurídica especializada')

        expect(items[1]['title']).to eq('Mandado de Segurança')
        expect(items[1]['value']).to eq('option_2')
        expect(items[1]['description']).to eq('Proteção de direitos líquidos e certos')
      end

      it 'generates appropriate fallback text' do
        result = described_class.map(list_payload)

        expect(result.fallback_text).to include('Escolha uma opção')
        expect(result.fallback_text).to include('2 options')
      end
    end

    context 'with URL button' do
      let(:url_button_payload) do
        {
          'type' => 'button',
          'body' => {
            'text' => 'Visite nosso site'
          },
          'action' => {
            'buttons' => [
              {
                'type' => 'url',
                'title' => 'Acessar Site',
                'url' => 'https://example.com'
              }
            ]
          }
        }
      end

      it 'maps URL buttons correctly' do
        result = described_class.map(url_button_payload)
        action = result.content_attributes['items'].first['actions'].first

        expect(action['type']).to eq('link')
        expect(action['text']).to eq('Acessar Site')
        expect(action['uri']).to eq('https://example.com')
      end
    end

    context 'with invalid payloads' do
      it 'handles nil payload' do
        result = described_class.map(nil)

        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('WhatsApp interactive message')
      end

      it 'handles empty payload' do
        result = described_class.map({})

        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('WhatsApp interactive message')
      end

      it 'handles payload without type' do
        result = described_class.map({ 'body' => { 'text' => 'Test' } })

        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('WhatsApp interactive message')
      end

      it 'handles unknown interactive type' do
        result = described_class.map({
          'type' => 'unknown_type',
          'body' => { 'text' => 'Test message' }
        })

        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('Test message')
      end
    end

    context 'with security considerations' do
      it 'sanitizes malicious URLs' do
        malicious_payload = {
          'type' => 'button',
          'body' => { 'text' => 'Test' },
          'action' => {
            'buttons' => [
              {
                'type' => 'url',
                'title' => 'Malicious Link',
                'url' => 'javascript:alert("xss")'
              }
            ]
          }
        }

        result = described_class.map(malicious_payload)
        card = result.content_attributes['items'].first

        expect(card['actions']).to be_empty
      end

      it 'rejects localhost URLs' do
        localhost_payload = {
          'type' => 'button',
          'body' => { 'text' => 'Test' },
          'action' => {
            'buttons' => [
              {
                'type' => 'url',
                'title' => 'Local Link',
                'url' => 'http://localhost:3000/admin'
              }
            ]
          }
        }

        result = described_class.map(localhost_payload)
        card = result.content_attributes['items'].first

        expect(card['actions']).to be_empty
      end

      it 'handles oversized payloads' do
        large_text = 'A' * 30000  # Larger than 25KB limit
        large_payload = {
          'type' => 'button',
          'body' => { 'text' => large_text },
          'action' => { 'buttons' => [] }
        }

        result = described_class.map(large_payload)

        expect(result.content_type).to eq('text')
        expect(result.fallback_text).to eq('WhatsApp interactive message')
      end
    end

    context 'with text truncation' do
      it 'truncates long titles' do
        long_title = 'A' * 200
        payload = {
          'type' => 'button',
          'body' => { 'text' => long_title },
          'action' => { 'buttons' => [] }
        }

        result = described_class.map(payload)
        card = result.content_attributes['items'].first

        expect(card['title'].length).to be <= 120
        expect(card['title']).to end_with('...')
      end

      it 'truncates long descriptions' do
        long_description = 'B' * 300
        payload = {
          'type' => 'button',
          'body' => { 'text' => 'Title' },
          'footer' => { 'text' => long_description },
          'action' => { 'buttons' => [] }
        }

        result = described_class.map(payload)
        card = result.content_attributes['items'].first

        expect(card['description'].length).to be <= 200
        expect(card['description']).to end_with('...')
      end

      it 'truncates button text' do
        long_button_text = 'C' * 100
        payload = {
          'type' => 'button',
          'body' => { 'text' => 'Test' },
          'action' => {
            'buttons' => [
              {
                'type' => 'reply',
                'reply' => {
                  'id' => 'btn_1',
                  'title' => long_button_text
                }
              }
            ]
          }
        }

        result = described_class.map(payload)
        action = result.content_attributes['items'].first['actions'].first

        expect(action['text'].length).to be <= 50
        expect(action['text']).to end_with('...')
      end
    end

    context 'with limits enforcement' do
      it 'limits number of buttons' do
        many_buttons = (1..5).map do |i|
          {
            'type' => 'reply',
            'reply' => {
              'id' => "btn_#{i}",
              'title' => "Button #{i}"
            }
          }
        end

        payload = {
          'type' => 'button',
          'body' => { 'text' => 'Test' },
          'action' => { 'buttons' => many_buttons }
        }

        result = described_class.map(payload)
        actions = result.content_attributes['items'].first['actions']

        expect(actions.length).to eq(3)  # MAX_BTNS = 3
      end

      it 'limits number of list options' do
        many_rows = (1..25).map do |i|
          {
            'id' => "option_#{i}",
            'title' => "Option #{i}",
            'description' => "Description #{i}"
          }
        end

        payload = {
          'type' => 'list',
          'body' => { 'text' => 'Choose' },
          'action' => {
            'sections' => [
              { 'rows' => many_rows }
            ]
          }
        }

        result = described_class.map(payload)
        items = result.content_attributes['items']

        expect(items.length).to eq(20)  # MAX_LIST_OPTIONS = 20
      end
    end

    context 'with caching' do
      let(:test_payload) do
        {
          'type' => 'button',
          'body' => { 'text' => 'Test message' },
          'action' => { 'buttons' => [] }
        }
      end

      it 'caches mapping results' do
        # Clear cache first
        Rails.cache.clear

        # First call should cache the result
        result1 = described_class.map(test_payload)
        
        # Second call should use cached result
        expect(Rails.cache).to receive(:fetch).and_call_original
        result2 = described_class.map(test_payload)

        expect(result1.content_type).to eq(result2.content_type)
        expect(result1.fallback_text).to eq(result2.fallback_text)
      end

      it 'generates consistent cache keys for same payload' do
        key1 = described_class.send(:generate_cache_key, test_payload)
        key2 = described_class.send(:generate_cache_key, test_payload)

        expect(key1).to eq(key2)
        expect(key1).to start_with('whatsapp_mapper:')
      end
    end
  end
end