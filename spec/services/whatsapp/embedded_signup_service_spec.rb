require 'rails_helper'

describe Whatsapp::EmbeddedSignupService do
  let(:account) { create(:account) }
  let(:code) { 'test_authorization_code' }
  let(:business_id) { 'test_business_id' }
  let(:waba_id) { 'test_waba_id' }
  let(:phone_number_id) { 'test_phone_number_id' }
  let(:service) do
    described_class.new(
      account: account,
      code: code,
      business_id: business_id,
      waba_id: waba_id,
      phone_number_id: phone_number_id
    )
  end

  describe '#perform' do
    let(:access_token) { 'test_access_token' }
    let(:phone_info) do
      {
        phone_number_id: phone_number_id,
        phone_number: '+1234567890',
        verified: true,
        business_name: 'Test Business'
      }
    end
    let(:channel) { instance_double(Channel::Whatsapp) }

    let(:token_exchange_service) { instance_double(Whatsapp::TokenExchangeService) }
    let(:phone_info_service) { instance_double(Whatsapp::PhoneInfoService) }
    let(:token_validation_service) { instance_double(Whatsapp::TokenValidationService) }
    let(:channel_creation_service) { instance_double(Whatsapp::ChannelCreationService) }

    before do
      allow(GlobalConfig).to receive(:clear_cache)

      allow(Whatsapp::TokenExchangeService).to receive(:new).with(code).and_return(token_exchange_service)
      allow(token_exchange_service).to receive(:perform).and_return(access_token)

      allow(Whatsapp::PhoneInfoService).to receive(:new)
        .with(waba_id, phone_number_id, access_token).and_return(phone_info_service)
      allow(phone_info_service).to receive(:perform).and_return(phone_info)

      allow(Whatsapp::TokenValidationService).to receive(:new)
        .with(access_token, waba_id).and_return(token_validation_service)
      allow(token_validation_service).to receive(:perform)

      allow(Whatsapp::ChannelCreationService).to receive(:new)
        .with(account, { waba_id: waba_id, business_name: 'Test Business' }, phone_info, access_token)
        .and_return(channel_creation_service)
      allow(channel_creation_service).to receive(:perform).and_return(channel)

      # Webhook setup is now handled in the channel after_create callback
      # So we stub it at the model level
      webhook_service = instance_double(Whatsapp::WebhookSetupService)
      allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_service)
      allow(webhook_service).to receive(:perform)
    end

    it 'orchestrates all services in the correct order' do
      expect(token_exchange_service).to receive(:perform).ordered
      expect(phone_info_service).to receive(:perform).ordered
      expect(token_validation_service).to receive(:perform).ordered
      expect(channel_creation_service).to receive(:perform).ordered

      result = service.perform
      expect(result).to eq(channel)
    end

    context 'when required parameters are missing' do
      it 'raises error when code is blank' do
        service = described_class.new(
          account: account,
          code: '',
          business_id: business_id,
          waba_id: waba_id,
          phone_number_id: phone_number_id
        )
        expect { service.perform }.to raise_error(ArgumentError, /Required parameters are missing: code/)
      end

      it 'raises error when business_id is blank' do
        service = described_class.new(
          account: account,
          code: code,
          business_id: '',
          waba_id: waba_id,
          phone_number_id: phone_number_id
        )
        expect { service.perform }.to raise_error(ArgumentError, /Required parameters are missing: business_id/)
      end

      it 'raises error when waba_id is blank' do
        service = described_class.new(
          account: account,
          code: code,
          business_id: business_id,
          waba_id: '',
          phone_number_id: phone_number_id
        )
        expect { service.perform }.to raise_error(ArgumentError, /Required parameters are missing: waba_id/)
      end

      it 'raises error when multiple parameters are blank' do
        service = described_class.new(
          account: account,
          code: '',
          business_id: '',
          waba_id: waba_id,
          phone_number_id: phone_number_id
        )
        expect { service.perform }.to raise_error(ArgumentError, /Required parameters are missing: code, business_id/)
      end
    end

    context 'when any service fails' do
      it 'logs and re-raises the error' do
        allow(token_exchange_service).to receive(:perform).and_raise('Token error')

        expect(Rails.logger).to receive(:error).with('[WHATSAPP] Embedded signup failed: Token error')
        expect { service.perform }.to raise_error('Token error')
      end
    end
  end
end
