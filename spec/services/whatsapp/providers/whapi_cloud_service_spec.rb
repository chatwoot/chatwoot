# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::Providers::WhapiCloudService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_light', provider_config: whapi_config) }
  let(:whapi_config) do
    {
      'api_url' => 'https://gate.whapi.cloud/',
      'token' => 'test_token_123',
      'channel_id' => 'test_channel_id',
      'phone' => '1234567890'
    }
  end

  before do
    # Stub health check for provider validation
    stub_request(:get, "#{whapi_config['api_url']}health")
      .to_return(status: 200, body: { status: 'ok' }.to_json)
  end

  describe '#send_message' do
    let(:contact) { create(:contact, account: whatsapp_channel.account) }
    let(:contact_inbox) { create(:contact_inbox, inbox: whatsapp_channel.inbox, contact: contact, source_id: '1234567890') }
    let(:conversation) { create(:conversation, inbox: whatsapp_channel.inbox, contact: contact, contact_inbox: contact_inbox) }
    let(:message) { create(:message, inbox: whatsapp_channel.inbox, conversation: conversation, content: 'Incoming Message', message_type: :outgoing) }

    context 'sending text message' do
      before do
        stub_request(:post, "https://gate.whapi.cloud/messages/text")
          .to_return(
            status: 200,
            body: { sent: true, message: { id: 'msg_123' } }.to_json
          )
      end

      it 'sends text message successfully and returns message ID' do
        service = described_class.new(whatsapp_channel: whatsapp_channel)
        result = service.send_message(contact_inbox.source_id, message)

        expect(result).to eq('msg_123')
        expect(WebMock).to have_requested(:post, "https://gate.whapi.cloud/messages/text")
      end

      it 'sends correct payload to Whapi API' do
        service = described_class.new(whatsapp_channel: whatsapp_channel)
        service.send_message(contact_inbox.source_id, message)

        expect(WebMock).to have_requested(:post, "https://gate.whapi.cloud/messages/text")
          .with(
            headers: {
              'Authorization' => "Bearer #{whapi_config['token']}",
              'Content-Type' => 'application/json'
            },
            body: hash_including(
              to: contact_inbox.source_id,
              body: message.content
            )
          )
      end
    end

    context 'when API returns error' do
      before do
        stub_request(:post, "https://gate.whapi.cloud/messages/text")
          .to_return(status: 400, body: { error: 'Bad request' }.to_json)
      end

      it 'returns nil on error' do
        service = described_class.new(whatsapp_channel: whatsapp_channel)
        result = service.send_message(contact_inbox.source_id, message)

        expect(result).to be_nil
      end
    end

    context 'phone number formatting' do
      before do
        stub_request(:post, "https://gate.whapi.cloud/messages/text")
          .to_return(status: 200, body: { sent: true, message: { id: 'msg_123' } }.to_json)
      end

      it 'formats phone numbers correctly by removing +' do
        service = described_class.new(whatsapp_channel: whatsapp_channel)
        service.send_message('+1234567890', message)

        expect(WebMock).to have_requested(:post, "https://gate.whapi.cloud/messages/text")
          .with(body: hash_including(to: '1234567890'))
      end
    end
  end

  describe '#sync_templates' do
    it 'returns true as WhatsApp Light does not support templates' do
      service = described_class.new(whatsapp_channel: whatsapp_channel)
      expect(service.sync_templates).to be_truthy
    end
  end

  describe '#validate_provider_config?' do
    it 'validates required config fields' do
      service = described_class.new(whatsapp_channel: whatsapp_channel)
      expect(service.validate_provider_config?).to be_truthy
    end

    context 'when token is missing' do
      before do
        whatsapp_channel.provider_config.delete('token')
      end

      it 'returns false' do
        service = described_class.new(whatsapp_channel: whatsapp_channel)
        expect(service.validate_provider_config?).to be_falsey
      end
    end
  end
end
