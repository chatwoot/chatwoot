# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::SocialwiseFlow::WhatsappResponseProcessor do
  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
  let(:inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, contact: contact, inbox: inbox, account: account) }
  let(:message) { create(:message, conversation: conversation, account: account, inbox: inbox) }

  describe '.process' do
    context 'with interactive button message' do
      let(:whatsapp_payload) do
        {
          'type' => 'interactive',
          'interactive' => {
            'type' => 'button',
            'body' => {
              'text' => 'Escolha uma opção:'
            },
            'action' => {
              'buttons' => [
                {
                  'type' => 'reply',
                  'reply' => {
                    'id' => 'btn_1',
                    'title' => 'Opção 1'
                  }
                },
                {
                  'type' => 'reply',
                  'reply' => {
                    'id' => 'btn_2',
                    'title' => 'Opção 2'
                  }
                }
              ]
            }
          }
        }
      end

      it 'processes interactive button message successfully' do
        expect(Rails.logger).to receive(:info).with(/STARTING WHATSAPP RESPONSE PROCESSING/).at_least(:once)
        expect(Rails.logger).to receive(:info).with(/Processing Interactive Message/).at_least(:once)
        expect(Rails.logger).to receive(:info).with(/INTERACTIVE MESSAGE SEND COMPLETED/).at_least(:once)

        result = described_class.process(whatsapp_payload, message)
        expect(result).to be true
      end

      it 'creates rich outgoing message' do
        # Enable rich dashboard feature for account
        allow(account).to receive(:feature_enabled?).with('SOCIALWISE_RICH_DASHBOARD').and_return(true)

        expect {
          described_class.process(whatsapp_payload, message)
        }.to change { conversation.messages.outgoing.count }.by(1)

        outgoing_message = conversation.messages.outgoing.last
        expect(outgoing_message.content_type).to eq('integrations')
        expect(outgoing_message.content_attributes).to have_key('interactive')
        expect(outgoing_message.additional_attributes['socialwise_flow_message']).to be true
        expect(outgoing_message.additional_attributes['skip_send_reply']).to be true
      end

      it 'creates text fallback when rich dashboard is disabled' do
        # Disable rich dashboard feature for account
        allow(account).to receive(:feature_enabled?).with('SOCIALWISE_RICH_DASHBOARD').and_return(false)

        expect {
          described_class.process(whatsapp_payload, message)
        }.to change { conversation.messages.outgoing.count }.by(1)

        outgoing_message = conversation.messages.outgoing.last
        expect(outgoing_message.content_type).to eq('text')
        expect(outgoing_message.content).to eq('Escolha uma opção:')
      end
    end

    context 'with interactive list message' do
      let(:whatsapp_payload) do
        {
          'type' => 'interactive',
          'interactive' => {
            'type' => 'list',
            'body' => {
              'text' => 'Selecione uma categoria:'
            },
            'action' => {
              'button' => 'Ver opções',
              'sections' => [
                {
                  'title' => 'Categoria 1',
                  'rows' => [
                    {
                      'id' => 'row_1',
                      'title' => 'Item 1',
                      'description' => 'Descrição do item 1'
                    }
                  ]
                }
              ]
            }
          }
        }
      end

      it 'processes interactive list message successfully' do
        expect(Rails.logger).to receive(:info).with(/STARTING WHATSAPP RESPONSE PROCESSING/).at_least(:once)
        expect(Rails.logger).to receive(:info).with(/Processing Interactive Message/).at_least(:once)

        result = described_class.process(whatsapp_payload, message)
        expect(result).to be true
      end

      it 'creates rich outgoing message with list content' do
        # Enable rich dashboard feature for account
        allow(account).to receive(:feature_enabled?).with('SOCIALWISE_RICH_DASHBOARD').and_return(true)

        expect {
          described_class.process(whatsapp_payload, message)
        }.to change { conversation.messages.outgoing.count }.by(1)

        outgoing_message = conversation.messages.outgoing.last
        expect(outgoing_message.content_type).to eq('integrations')
        expect(outgoing_message.content_attributes['interactive']['type']).to eq('list')
      end
    end

    context 'with text message' do
      let(:whatsapp_payload) do
        {
          'type' => 'text',
          'text' => {
            'body' => 'Esta é uma mensagem de texto simples'
          }
        }
      end

      it 'processes text message successfully' do
        expect(Rails.logger).to receive(:info).with(/STARTING WHATSAPP RESPONSE PROCESSING/).at_least(:once)
        expect(Rails.logger).to receive(:info).with(/Processing Text Message/).at_least(:once)

        result = described_class.process(whatsapp_payload, message)
        expect(result).to be true
      end

      it 'creates text outgoing message' do
        expect {
          described_class.process(whatsapp_payload, message)
        }.to change { conversation.messages.outgoing.count }.by(1)

        outgoing_message = conversation.messages.outgoing.last
        expect(outgoing_message.content_type).to eq('text')
        expect(outgoing_message.content).to eq('Esta é uma mensagem de texto simples')
      end
    end

    context 'with invalid payload' do
      it 'handles invalid payload gracefully' do
        expect(Rails.logger).to receive(:error).with(/Invalid whatsapp_data/).at_least(:once)

        result = described_class.process('invalid', message)
        expect(result).to be false
      end

      it 'creates fallback message for invalid payload' do
        expect {
          described_class.process('invalid', message)
        }.to change { conversation.messages.outgoing.count }.by(1)

        outgoing_message = conversation.messages.outgoing.last
        expect(outgoing_message.content).to eq('WhatsApp message')
      end
    end

    context 'with non-WhatsApp channel' do
      let(:facebook_channel) { create(:channel_facebook_page, account: account) }
      let(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }
      let(:facebook_conversation) { create(:conversation, contact: contact, inbox: facebook_inbox, account: account) }
      let(:facebook_message) { create(:message, conversation: facebook_conversation, account: account, inbox: facebook_inbox) }

      let(:whatsapp_payload) do
        {
          'type' => 'interactive',
          'interactive' => {
            'type' => 'button',
            'body' => { 'text' => 'Test' }
          }
        }
      end

      it 'handles non-WhatsApp channel gracefully' do
        expect(Rails.logger).to receive(:warn).with(/Rich messages only supported for WhatsApp channels/).at_least(:once)

        result = described_class.process(whatsapp_payload, facebook_message)
        expect(result).to be false
      end
    end

    context 'with missing interactive payload' do
      let(:whatsapp_payload) do
        {
          'type' => 'interactive'
          # missing 'interactive' key
        }
      end

      it 'handles missing interactive payload gracefully' do
        expect(Rails.logger).to receive(:error).with(/Missing interactive payload/).at_least(:once)

        result = described_class.process(whatsapp_payload, message)
        expect(result).to be false
      end
    end
  end

  describe 'performance metrics' do
    let(:whatsapp_payload) do
      {
        'type' => 'interactive',
        'interactive' => {
          'type' => 'button',
          'body' => { 'text' => 'Performance test' },
          'action' => {
            'buttons' => [
              { 'type' => 'reply', 'reply' => { 'id' => 'btn_1', 'title' => 'Button 1' } }
            ]
          }
        }
      }
    end

    it 'logs performance metrics' do
      expect(Rails.logger).to receive(:info).with(/PERFORMANCE METRICS/).at_least(:once)
      expect(Rails.logger).to receive(:info).with(/Duration:/).at_least(:once)

      described_class.process(whatsapp_payload, message)
    end

    it 'logs performance warnings for slow operations' do
      # Mock slow operation
      allow(Messages::WhatsappRendererMapper).to receive(:map).and_wrap_original do |method, *args|
        sleep(0.1) # Simulate slow operation
        method.call(*args)
      end

      expect(Rails.logger).to receive(:info).with(/PERFORMANCE METRICS/).at_least(:once)

      described_class.process(whatsapp_payload, message)
    end
  end

  describe 'error handling' do
    let(:whatsapp_payload) do
      {
        'type' => 'interactive',
        'interactive' => {
          'type' => 'button',
          'body' => { 'text' => 'Error test' }
        }
      }
    end

    it 'handles exceptions gracefully' do
      # Mock an exception in the renderer mapper
      allow(Messages::WhatsappRendererMapper).to receive(:map).and_raise(StandardError, 'Test error')

      expect(Rails.logger).to receive(:error).with(/Interactive message send failed/).at_least(:once)
      expect(Rails.logger).to receive(:info).with(/Falling back to text message/).at_least(:once)

      result = described_class.process(whatsapp_payload, message)
      expect(result).to be false
    end

    it 'creates fallback message when processing fails' do
      # Mock an exception in the renderer mapper
      allow(Messages::WhatsappRendererMapper).to receive(:map).and_raise(StandardError, 'Test error')

      expect {
        described_class.process(whatsapp_payload, message)
      }.to change { conversation.messages.outgoing.count }.by(1)

      outgoing_message = conversation.messages.outgoing.last
      expect(outgoing_message.content).to eq('Error test')
    end
  end
end