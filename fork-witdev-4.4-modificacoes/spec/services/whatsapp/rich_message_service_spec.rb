# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::RichMessageService do
  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
  let(:inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, contact: contact, account: account) }
  let(:message) { create(:message, conversation: conversation, account: account, message_type: :outgoing) }

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

  describe '#perform' do
    let(:service) { described_class.new(message: message, interactive_payload: button_payload) }

    before do
      # Enable rich dashboard feature
      account.enable_features('SOCIALWISE_RICH_DASHBOARD')
      account.save!

      # Mock contact source ID
      allow(contact).to receive(:get_source_id).with(inbox.id).and_return('+1234567890')

      # Mock WhatsApp provider
      provider_double = double('WhatsappCloudService')
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_double)
      allow(provider_double).to receive(:send_interactive_text_message).and_return({ success: true })
    end

    context 'with valid button payload' do
      it 'processes the message successfully' do
        expect { service.perform }.not_to raise_error
      end

      it 'updates message with rich content for dashboard' do
        service.perform

        message.reload
        expect(message.content_type).to eq('cards')
        expect(message.content_attributes['items']).to be_an(Array)
        expect(message.content_attributes['items'].length).to eq(1)
      end

      it 'uses WhatsappRendererMapper for content mapping' do
        expect(Messages::WhatsappRendererMapper).to receive(:map).with(button_payload).and_call_original

        service.perform
      end

      it 'calls WhatsApp provider to send message' do
        provider_double = double('WhatsappCloudService')
        expect(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_double)
        expect(provider_double).to receive(:send_interactive_text_message).with('+1234567890', message)

        service.perform
      end

      it 'stores interactive payload in message content_attributes' do
        service.perform

        message.reload
        expect(message.content_attributes['interactive_payload']).to eq(button_payload)
      end
    end

    context 'with valid list payload' do
      let(:service) { described_class.new(message: message, interactive_payload: list_payload) }

      it 'processes list payload correctly' do
        service.perform

        message.reload
        expect(message.content_type).to eq('input_select')
        expect(message.content_attributes['items']).to be_an(Array)
        expect(message.content_attributes['items'].length).to eq(2)
      end

      it 'maps list options correctly' do
        service.perform

        message.reload
        items = message.content_attributes['items']
        expect(items[0]['title']).to eq('Consultoria Jurídica')
        expect(items[0]['value']).to eq('option_1')
        expect(items[1]['title']).to eq('Mandado de Segurança')
        expect(items[1]['value']).to eq('option_2')
      end
    end

    # Feature flag dependency removed - dashboard mirroring always happens for interactive messages

    context 'when message is already rich' do
      before do
        message.update!(content_type: 'cards', content_attributes: { 'items' => [] })
      end

      it 'skips dashboard mirroring' do
        expect(Messages::WhatsappRendererMapper).not_to receive(:map)

        service.perform
      end

      it 'still sends WhatsApp message' do
        provider_double = double('WhatsappCloudService')
        expect(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_double)
        expect(provider_double).to receive(:send_interactive_text_message)

        service.perform
      end
    end

    context 'with error handling' do
      it 'handles mapper errors gracefully' do
        allow(Messages::WhatsappRendererMapper).to receive(:map).and_raise(StandardError, 'Mapper error')
        allow(Rails.logger).to receive(:error)

        expect { service.perform }.not_to raise_error
      end

      it 'continues with WhatsApp send even if mirroring fails' do
        allow(Messages::WhatsappRendererMapper).to receive(:map).and_raise(StandardError, 'Mapper error')
        allow(Rails.logger).to receive(:error)

        provider_double = double('WhatsappCloudService')
        expect(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_double)
        expect(provider_double).to receive(:send_interactive_text_message)

        service.perform
      end

      it 'handles WhatsApp send errors with fallback' do
        provider_double = double('WhatsappCloudService')
        allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(provider_double)
        allow(provider_double).to receive(:send_interactive_text_message).and_raise(StandardError, 'Send failed')
        allow(provider_double).to receive(:send_text_message).and_return({ success: true })

        expect { service.perform }.not_to raise_error
        expect(provider_double).to have_received(:send_text_message)
      end
    end

    context 'with different WhatsApp providers' do
      it 'uses whatsapp_cloud provider by default' do
        whatsapp_channel.update!(provider: 'whatsapp_cloud')

        expect(Whatsapp::Providers::WhatsappCloudService).to receive(:new).with(whatsapp_channel: whatsapp_channel)

        service.perform
      end

      it 'uses unoapi provider when configured' do
        whatsapp_channel.update!(provider: 'unoapi')

        expect(Whatsapp::Providers::Whatsapp360DialogService).to receive(:new).with(whatsapp_channel: whatsapp_channel)

        service.perform
      end

      it 'defaults to whatsapp_cloud for unknown providers' do
        whatsapp_channel.update!(provider: 'unknown_provider')

        expect(Whatsapp::Providers::WhatsappCloudService).to receive(:new).with(whatsapp_channel: whatsapp_channel)

        service.perform
      end
    end

    context 'with validation errors' do
      it 'raises error for non-outgoing message' do
        message.update!(message_type: :incoming)

        expect { service.perform }.not_to raise_error
        # Should log warning and skip processing
      end

      it 'raises error for private message' do
        message.update!(private: true)

        expect { service.perform }.not_to raise_error
        # Should log warning and skip processing
      end

      it 'raises error for non-WhatsApp channel' do
        instagram_channel = create(:channel_instagram_fb_page, account: account)
        instagram_inbox = create(:inbox, channel: instagram_channel, account: account)
        instagram_conversation = create(:conversation, inbox: instagram_inbox, contact: contact, account: account)
        instagram_message = create(:message, conversation: instagram_conversation, account: account, message_type: :outgoing)

        service = described_class.new(message: instagram_message, interactive_payload: button_payload)

        expect { service.perform }.to raise_error(ArgumentError, 'Channel must be WhatsApp')
      end

      it 'raises error for blank phone number' do
        allow(contact).to receive(:get_source_id).with(inbox.id).and_return(nil)

        expect { service.perform }.to raise_error(ArgumentError, 'Phone number is required')
      end
    end
  end

  describe 'private methods' do
    let(:service) { described_class.new(message: message, interactive_payload: button_payload) }

    before do
      account.enable_features('SOCIALWISE_RICH_DASHBOARD')
      account.save!
      allow(contact).to receive(:get_source_id).with(inbox.id).and_return('+1234567890')
    end

    describe '#extract_fallback_text' do
      it 'uses mapper for fallback text' do
        expect(Messages::WhatsappRendererMapper).to receive(:map).with(button_payload).and_call_original

        fallback_text = service.send(:extract_fallback_text)
        expect(fallback_text).to be_a(String)
        expect(fallback_text).not_to be_empty
      end

      it 'handles mapper errors gracefully' do
        allow(Messages::WhatsappRendererMapper).to receive(:map).and_raise(StandardError, 'Test error')

        fallback_text = service.send(:extract_fallback_text)
        expect(fallback_text).to eq('Mensagem interativa do WhatsApp')
      end
    end

    # Feature flag dependency removed - interactive messages are always displayed as core functionality

    describe '#message_already_rich?' do
      it 'returns false for text messages' do
        message.update!(content_type: 'text')

        expect(service.send(:message_already_rich?)).to be false
      end

      it 'returns true for cards messages' do
        message.update!(content_type: 'cards')

        expect(service.send(:message_already_rich?)).to be true
      end

      it 'returns true for input_select messages' do
        message.update!(content_type: 'input_select')

        expect(service.send(:message_already_rich?)).to be true
      end
    end
  end
end