# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WhatsApp Rich Message Dashboard Integration', type: :integration do
  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
  let(:inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, contact: contact, account: account) }

  before do
    # Enable rich dashboard feature
    account.enable_features('SOCIALWISE_RICH_DASHBOARD')
    account.save!

    # Mock contact source ID
    allow_any_instance_of(Contact).to receive(:get_source_id).and_return('+1234567890')

    # Mock WhatsApp provider to avoid actual API calls
    provider_double = double('WhatsappCloudService')
    allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_double)
    allow(provider_double).to receive(:send_interactive_text_message).and_return({ success: true })
  end

  describe 'Button Template Processing' do
    let(:socialwise_button_payload) do
      {
        'type' => 'interactive',
        'interactive' => {
          'type' => 'button',
          'body' => {
            'text' => '> Sr(a) *Cliente*, \nSomos especializados em mandado de segurança...'
          },
          'header' => {
            'type' => 'image',
            'image' => {
              'link' => 'https://objstoreapi.witdev.com.br/chatwit-social/33ad7e6c-7524-4bbb-a7f5-80d35768b3f8.png'
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
      }
    end

    it 'processes SocialWise Flow button payload correctly' do
      # Create outgoing message
      message = conversation.messages.create!(
        content: 'Processing interactive message...',
        message_type: :outgoing,
        account: account,
        inbox: inbox
      )

      # Process with WhatsApp Rich Message Service
      service = Whatsapp::RichMessageService.new(
        message: message,
        interactive_payload: socialwise_button_payload['interactive']
      )

      expect { service.perform }.not_to raise_error

      # Verify message was updated with rich content
      message.reload
      expect(message.content_type).to eq('cards')
      expect(message.content_attributes['items']).to be_an(Array)
      expect(message.content_attributes['items'].length).to eq(1)

      # Verify card content
      card = message.content_attributes['items'].first
      expect(card['title']).to include('Sr(a) *Cliente*')
      expect(card['description']).to eq('Dra. Amanda Sousa Advocacia e Consultoria Jurídica™')
      expect(card['media_url']).to eq('https://objstoreapi.witdev.com.br/chatwit-social/33ad7e6c-7524-4bbb-a7f5-80d35768b3f8.png')

      # Verify button action
      expect(card['actions']).to be_an(Array)
      expect(card['actions'].length).to eq(1)
      action = card['actions'].first
      expect(action['type']).to eq('postback')
      expect(action['text']).to eq('Falar com a Dra')
      expect(action['payload']).to eq('btn_1756139209769_0_u8bq')

      # Verify fallback text
      expect(message.content).to include('Sr(a) *Cliente*')
      expect(message.content).to include('Falar com a Dra')
    end

    it 'stores interactive payload for WhatsApp API' do
      message = conversation.messages.create!(
        content: 'Processing interactive message...',
        message_type: :outgoing,
        account: account,
        inbox: inbox
      )

      service = Whatsapp::RichMessageService.new(
        message: message,
        interactive_payload: socialwise_button_payload['interactive']
      )

      service.perform

      message.reload
      expect(message.content_attributes['interactive_payload']).to eq(socialwise_button_payload['interactive'])
    end
  end

  describe 'List Template Processing' do
    let(:socialwise_list_payload) do
      {
        'type' => 'interactive',
        'interactive' => {
          'type' => 'list',
          'body' => {
            'text' => 'Escolha o serviço jurídico que precisa:'
          },
          'footer' => {
            'text' => 'Dra. Amanda Sousa - Advocacia Especializada'
          },
          'action' => {
            'button' => 'Ver Serviços',
            'sections' => [
              {
                'title' => 'Serviços Jurídicos',
                'rows' => [
                  {
                    'id' => 'mandado_seguranca',
                    'title' => 'Mandado de Segurança',
                    'description' => 'Proteção de direitos líquidos e certos'
                  },
                  {
                    'id' => 'consultoria_juridica',
                    'title' => 'Consultoria Jurídica',
                    'description' => 'Orientação jurídica especializada'
                  },
                  {
                    'id' => 'revisao_contratos',
                    'title' => 'Revisão de Contratos',
                    'description' => 'Análise e revisão de documentos'
                  }
                ]
              }
            ]
          }
        }
      }
    end

    it 'processes SocialWise Flow list payload correctly' do
      message = conversation.messages.create!(
        content: 'Processing list message...',
        message_type: :outgoing,
        account: account,
        inbox: inbox
      )

      service = Whatsapp::RichMessageService.new(
        message: message,
        interactive_payload: socialwise_list_payload['interactive']
      )

      expect { service.perform }.not_to raise_error

      # Verify message was updated with input_select content
      message.reload
      expect(message.content_type).to eq('input_select')
      expect(message.content_attributes['items']).to be_an(Array)
      expect(message.content_attributes['items'].length).to eq(3)

      # Verify list options
      items = message.content_attributes['items']
      
      expect(items[0]['title']).to eq('Mandado de Segurança')
      expect(items[0]['value']).to eq('mandado_seguranca')
      expect(items[0]['description']).to eq('Proteção de direitos líquidos e certos')

      expect(items[1]['title']).to eq('Consultoria Jurídica')
      expect(items[1]['value']).to eq('consultoria_juridica')
      expect(items[1]['description']).to eq('Orientação jurídica especializada')

      expect(items[2]['title']).to eq('Revisão de Contratos')
      expect(items[2]['value']).to eq('revisao_contratos')
      expect(items[2]['description']).to eq('Análise e revisão de documentos')

      # Verify fallback text
      expect(message.content).to include('Escolha o serviço jurídico')
      expect(message.content).to include('3 options')
    end
  end

  describe 'Dashboard Component Integration' do
    it 'creates messages compatible with RichCards.vue component' do
      message = conversation.messages.create!(
        content: 'Processing button message...',
        message_type: :outgoing,
        account: account,
        inbox: inbox
      )

      button_payload = {
        'type' => 'button',
        'body' => { 'text' => 'Test message with button' },
        'action' => {
          'buttons' => [
            {
              'type' => 'reply',
              'reply' => { 'id' => 'test_btn', 'title' => 'Test Button' }
            }
          ]
        }
      }

      service = Whatsapp::RichMessageService.new(
        message: message,
        interactive_payload: button_payload
      )

      service.perform

      message.reload

      # Verify structure matches RichCards.vue expectations
      expect(message.content_type).to eq('cards')
      expect(message.content_attributes).to have_key('items')
      
      card = message.content_attributes['items'].first
      expect(card).to have_key('title')
      expect(card).to have_key('actions')
      
      action = card['actions'].first
      expect(action).to have_key('type')
      expect(action).to have_key('text')
      expect(action).to have_key('payload')
    end

    it 'creates messages compatible with QuickReplies.vue component' do
      message = conversation.messages.create!(
        content: 'Processing list message...',
        message_type: :outgoing,
        account: account,
        inbox: inbox
      )

      list_payload = {
        'type' => 'list',
        'body' => { 'text' => 'Choose an option' },
        'action' => {
          'sections' => [
            {
              'rows' => [
                { 'id' => 'opt1', 'title' => 'Option 1', 'description' => 'First option' },
                { 'id' => 'opt2', 'title' => 'Option 2', 'description' => 'Second option' }
              ]
            }
          ]
        }
      }

      service = Whatsapp::RichMessageService.new(
        message: message,
        interactive_payload: list_payload
      )

      service.perform

      message.reload

      # Verify structure matches QuickReplies.vue expectations (input_select)
      expect(message.content_type).to eq('input_select')
      expect(message.content_attributes).to have_key('items')
      
      items = message.content_attributes['items']
      expect(items).to be_an(Array)
      
      item = items.first
      expect(item).to have_key('title')
      expect(item).to have_key('value')
      expect(item).to have_key('description')
    end
  end

  describe 'Error Handling and Fallbacks' do
    it 'handles mapper errors gracefully' do
      message = conversation.messages.create!(
        content: 'Processing message...',
        message_type: :outgoing,
        account: account,
        inbox: inbox
      )

      # Mock mapper to fail
      allow(Messages::WhatsappRendererMapper).to receive(:map).and_raise(StandardError, 'Test error')
      allow(Rails.logger).to receive(:error)

      invalid_payload = { 'type' => 'button', 'invalid' => true }

      service = Whatsapp::RichMessageService.new(
        message: message,
        interactive_payload: invalid_payload
      )

      expect { service.perform }.not_to raise_error

      # Should still attempt to send via WhatsApp API
      expect(Rails.logger).to have_received(:error).with(/Dashboard mirroring failed/)
    end

    it 'continues processing when rich dashboard is disabled' do
      # Disable rich dashboard
      account.disable_features('SOCIALWISE_RICH_DASHBOARD')
      account.save!

      message = conversation.messages.create!(
        content: 'Processing message...',
        message_type: :outgoing,
        account: account,
        inbox: inbox
      )

      button_payload = {
        'type' => 'button',
        'body' => { 'text' => 'Test' },
        'action' => { 'buttons' => [] }
      }

      service = Whatsapp::RichMessageService.new(
        message: message,
        interactive_payload: button_payload
      )

      expect { service.perform }.not_to raise_error

      # Message should not be updated with rich content
      message.reload
      expect(message.content_type).not_to eq('cards')
      expect(message.content_type).not_to eq('input_select')
    end

    it 'handles invalid payloads with fallback text' do
      message = conversation.messages.create!(
        content: 'Processing message...',
        message_type: :outgoing,
        account: account,
        inbox: inbox
      )

      invalid_payload = { 'invalid' => 'payload' }

      service = Whatsapp::RichMessageService.new(
        message: message,
        interactive_payload: invalid_payload
      )

      expect { service.perform }.not_to raise_error

      message.reload
      expect(message.content_type).to eq('text')
      expect(message.content).to eq('WhatsApp interactive message')
    end
  end

  describe 'Performance and Caching' do
    it 'uses caching for repeated payloads' do
      # Clear cache first
      Rails.cache.clear

      message1 = conversation.messages.create!(
        content: 'First message',
        message_type: :outgoing,
        account: account,
        inbox: inbox
      )

      message2 = conversation.messages.create!(
        content: 'Second message',
        message_type: :outgoing,
        account: account,
        inbox: inbox
      )

      same_payload = {
        'type' => 'button',
        'body' => { 'text' => 'Same payload' },
        'action' => { 'buttons' => [] }
      }

      # First call should cache the result
      service1 = Whatsapp::RichMessageService.new(
        message: message1,
        interactive_payload: same_payload
      )
      service1.perform

      # Second call should use cached result
      expect(Rails.cache).to receive(:fetch).and_call_original
      service2 = Whatsapp::RichMessageService.new(
        message: message2,
        interactive_payload: same_payload
      )
      service2.perform

      # Both messages should have same content structure
      message1.reload
      message2.reload
      expect(message1.content_type).to eq(message2.content_type)
      expect(message1.content).to eq(message2.content)
    end
  end
end