# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::IncomingMessageServiceFactory do
  describe '.create' do
    let(:inbox) { create(:inbox) }
    let(:params) { { 'test' => 'data' } }
    let(:correlation_id) { 'test-correlation-id' }

    before do
      # Stub HTTP calls for all providers
      # WhatsApp Cloud API
      stub_request(:get, %r{https://graph\.facebook\.com/v14\.0/.*/message_templates\?access_token=.*})
        .to_return(status: 200, body: { data: [] }.to_json)
      
      # WHAPI health check
      stub_request(:get, 'https://gate.whapi.cloud/health')
        .to_return(status: 200, body: '{}')
      
      # 360Dialog webhook and templates
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
        .to_return(status: 200, body: '{}')
      
      stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
        .to_return(status: 200, body: { templates: [] }.to_json)
    end

    context 'when provider is whatsapp_cloud' do
      let(:channel) do
        ch = build(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
        allow(ch).to receive(:sync_templates)
        ch.save!(validate: false)
        ch.inbox = inbox
        ch
      end

      it 'returns IncomingMessageWhatsappCloudService instance' do
        service = described_class.create(channel: channel, params: params, correlation_id: correlation_id)

        expect(service).to be_a(Whatsapp::IncomingMessageWhatsappCloudService)
        expect(service.send(:inbox)).to eq(inbox)
        expect(service.send(:params)['correlation_id']).to eq(correlation_id)
        expect(service.send(:params)['test']).to eq('data')
      end
    end

    context 'when provider is whapi' do
      let(:channel) do
        ch = build(:channel_whatsapp, provider: 'whapi', sync_templates: false, validate_provider_config: false)
        allow(ch).to receive(:sync_templates)
        ch.save!(validate: false)
        ch.inbox = inbox
        ch
      end

      it 'returns IncomingMessageWhapiService instance' do
        service = described_class.create(channel: channel, params: params, correlation_id: correlation_id)

        expect(service).to be_a(Whatsapp::IncomingMessageWhapiService)
        expect(service.send(:inbox)).to eq(inbox)
        expect(service.send(:params)['correlation_id']).to eq(correlation_id)
        expect(service.send(:params)['test']).to eq('data')
      end
    end

    context 'when provider is default/unknown' do
      let(:channel) do
        ch = build(:channel_whatsapp, provider: 'default', sync_templates: false, validate_provider_config: false)
        allow(ch).to receive(:sync_templates)
        ch.save!(validate: false)
        ch.inbox = inbox
        ch
      end

      it 'returns IncomingMessageService instance' do
        service = described_class.create(channel: channel, params: params, correlation_id: correlation_id)

        expect(service).to be_a(Whatsapp::IncomingMessageService)
        expect(service.send(:inbox)).to eq(inbox)
        expect(service.send(:params)['correlation_id']).to eq(correlation_id)
        expect(service.send(:params)['test']).to eq('data')
      end
    end
  end

  describe '.service_class_for' do
    it 'returns correct service class for whatsapp_cloud' do
      expect(described_class.send(:service_class_for, 'whatsapp_cloud')).to eq(Whatsapp::IncomingMessageWhatsappCloudService)
    end

    it 'returns correct service class for whapi' do
      expect(described_class.send(:service_class_for, 'whapi')).to eq(Whatsapp::IncomingMessageWhapiService)
    end

    it 'returns default service class for unknown provider' do
      expect(described_class.send(:service_class_for, 'unknown')).to eq(Whatsapp::IncomingMessageService)
    end
  end

  describe 'error handling' do
    let(:inbox) { create(:inbox) }
    let(:params) { { 'test' => 'data' } }
    let(:correlation_id) { 'test-correlation-id' }
    let(:channel) do
      ch = build(:channel_whatsapp, provider: 'whatsapp_cloud', sync_templates: false, validate_provider_config: false)
      allow(ch).to receive(:sync_templates)
      ch.save!(validate: false)
      ch.inbox = inbox
      ch
    end

    it 'falls back to default service when service creation fails' do
      # Mock service class instantiation to fail
      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_raise(StandardError.new('Service creation failed'))
      allow(Rails.logger).to receive(:error)

      service = described_class.create(channel: channel, params: params, correlation_id: correlation_id)

      expect(service).to be_a(Whatsapp::IncomingMessageService)
      expect(service.send(:params)['correlation_id']).to eq(correlation_id)
      expect(Rails.logger).to have_received(:error).with(/Failed to create incoming message service/)
    end

    it 'handles correlation_id parameter correctly in fallback' do
      allow(Whatsapp::IncomingMessageWhatsappCloudService).to receive(:new).and_raise(StandardError)
      allow(Rails.logger).to receive(:error)

      service = described_class.create(channel: channel, params: params, correlation_id: correlation_id)

      expect(service.send(:params)).to include('correlation_id' => correlation_id, 'test' => 'data')
    end
  end
end