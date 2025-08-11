require 'rails_helper'

describe Whatsapp::EmbeddedSignupService do
  let(:account) { create(:account) }
  let(:params) do
    {
      code: 'test_authorization_code',
      business_id: 'test_business_id',
      waba_id: 'test_waba_id',
      phone_number_id: 'test_phone_number_id'
    }
  end
  let(:service) do
    described_class.new(
      account: account,
      params: params
    )
  end

  describe '#perform' do
    let(:access_token) { 'test_access_token' }
    let(:phone_info) do
      {
        phone_number_id: params[:phone_number_id],
        phone_number: '+1234567890',
        verified: true,
        business_name: 'Test Business'
      }
    end
    let(:channel) { instance_double(Channel::Whatsapp) }
    let(:service_doubles) do
      {
        token_exchange: instance_double(Whatsapp::TokenExchangeService),
        phone_info: instance_double(Whatsapp::PhoneInfoService),
        token_validation: instance_double(Whatsapp::TokenValidationService),
        channel_creation: instance_double(Whatsapp::ChannelCreationService)
      }
    end

    before do
      allow(GlobalConfig).to receive(:clear_cache)

      allow(Whatsapp::TokenExchangeService).to receive(:new).with(params[:code]).and_return(service_doubles[:token_exchange])
      allow(service_doubles[:token_exchange]).to receive(:perform).and_return(access_token)

      allow(Whatsapp::PhoneInfoService).to receive(:new)
        .with(params[:waba_id], params[:phone_number_id], access_token).and_return(service_doubles[:phone_info])
      allow(service_doubles[:phone_info]).to receive(:perform).and_return(phone_info)

      allow(Whatsapp::TokenValidationService).to receive(:new)
        .with(access_token, params[:waba_id]).and_return(service_doubles[:token_validation])
      allow(service_doubles[:token_validation]).to receive(:perform)

      allow(Whatsapp::ChannelCreationService).to receive(:new)
        .with(account, { waba_id: params[:waba_id], business_name: 'Test Business' }, phone_info, access_token)
        .and_return(service_doubles[:channel_creation])
      allow(service_doubles[:channel_creation]).to receive(:perform).and_return(channel)

      # Webhook setup is now handled in the channel after_create callback
      # So we stub it at the model level
      webhook_service = instance_double(Whatsapp::WebhookSetupService)
      allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_service)
      allow(webhook_service).to receive(:perform)
    end

    it 'orchestrates all services in the correct order' do
      expect(service_doubles[:token_exchange]).to receive(:perform).ordered
      expect(service_doubles[:phone_info]).to receive(:perform).ordered
      expect(service_doubles[:token_validation]).to receive(:perform).ordered
      expect(service_doubles[:channel_creation]).to receive(:perform).ordered

      result = service.perform
      expect(result).to eq(channel)
    end

    context 'when required parameters are missing' do
      it 'raises error when code is blank' do
        service = described_class.new(
          account: account,
          params: params.merge(code: '')
        )
        expect { service.perform }.to raise_error(ArgumentError, /Required parameters are missing: code/)
      end

      it 'raises error when business_id is blank' do
        service = described_class.new(
          account: account,
          params: params.merge(business_id: '')
        )
        expect { service.perform }.to raise_error(ArgumentError, /Required parameters are missing: business_id/)
      end

      it 'raises error when waba_id is blank' do
        service = described_class.new(
          account: account,
          params: params.merge(waba_id: '')
        )
        expect { service.perform }.to raise_error(ArgumentError, /Required parameters are missing: waba_id/)
      end

      it 'raises error when multiple parameters are blank' do
        service = described_class.new(
          account: account,
          params: params.merge(code: '', business_id: '')
        )
        expect { service.perform }.to raise_error(ArgumentError, /Required parameters are missing: code, business_id/)
      end
    end

    context 'when any service fails' do
      it 'logs and re-raises the error' do
        allow(service_doubles[:token_exchange]).to receive(:perform).and_raise('Token error')

        expect(Rails.logger).to receive(:error).with('[WHATSAPP] Embedded signup failed: Token error')
        expect { service.perform }.to raise_error('Token error')
      end
    end

    context 'when inbox_id is provided (reauthorization flow)' do
      let(:inbox_id) { 123 }
      let(:reauth_service) { instance_double(Whatsapp::ReauthorizationService) }
      let(:service_with_inbox) do
        described_class.new(
          account: account,
          params: params,
          inbox_id: inbox_id
        )
      end

      before do
        allow(Whatsapp::ReauthorizationService).to receive(:new).with(
          account: account,
          inbox_id: inbox_id,
          phone_number_id: params[:phone_number_id],
          business_id: params[:business_id]
        ).and_return(reauth_service)
        allow(reauth_service).to receive(:perform).with(access_token, phone_info).and_return(channel)
      end

      it 'uses ReauthorizationService instead of ChannelCreationService' do
        expect(service_doubles[:token_exchange]).to receive(:perform).ordered
        expect(service_doubles[:phone_info]).to receive(:perform).ordered
        expect(service_doubles[:token_validation]).to receive(:perform).ordered
        expect(reauth_service).to receive(:perform).with(access_token, phone_info).ordered
        expect(service_doubles[:channel_creation]).not_to receive(:perform)

        result = service_with_inbox.perform
        expect(result).to eq(channel)
      end
    end
  end
end
