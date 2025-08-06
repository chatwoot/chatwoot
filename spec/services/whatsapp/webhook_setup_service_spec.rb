require 'rails_helper'

describe Whatsapp::WebhookSetupService do
  let(:channel) do
    create(:channel_whatsapp,
           phone_number: '+1234567890',
           provider_config: {
             'phone_number_id' => 'test_phone_id',
             'webhook_verify_token' => 'test_verify_token'
           },
           provider: 'whatsapp_cloud',
           sync_templates: false,
           validate_provider_config: false)
  end
  let(:waba_id) { 'test_waba_id' }
  let(:access_token) { 'test_access_token' }
  let(:service) { described_class.new(channel, waba_id, access_token) }
  let(:api_client) { instance_double(Whatsapp::FacebookApiClient) }

  before do
    # Clean up any existing channels to avoid phone number conflicts
    Channel::Whatsapp.destroy_all
    allow(Whatsapp::FacebookApiClient).to receive(:new).and_return(api_client)
  end

  describe '#perform' do
    context 'when all operations succeed (classic flow)' do
      before do
        allow(GlobalConfigService).to receive(:load)
          .with('WHATSAPP_FEATURE_TYPE', '').and_return('')
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(service).to receive(:coexistence_method?).and_return(false)
        allow(api_client).to receive(:register_phone_number).with('123456789', 223_456)
        allow(api_client).to receive(:subscribe_waba_webhook)
          .with(waba_id, anything, 'test_verify_token')
          .and_return({ 'success' => true })
        allow(channel).to receive(:save!)
      end

      it 'registers the phone number' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number).with('123456789', 223_456)
          service.perform
        end
      end

      it 'sets up webhook subscription' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:subscribe_waba_webhook)
            .with(waba_id, 'https://app.chatwoot.com/webhooks/whatsapp/+1234567890', 'test_verify_token')
          service.perform
        end
      end
    end

    context 'when phone registration fails' do
      before do
        allow(GlobalConfigService).to receive(:load)
          .with('WHATSAPP_FEATURE_TYPE', '').and_return('')
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(service).to receive(:coexistence_method?).and_return(false)
        allow(api_client).to receive(:register_phone_number).and_raise('Registration failed')
        allow(api_client).to receive(:subscribe_waba_webhook).and_return({ 'success' => true })
      end

      it 'continues with webhook setup' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:subscribe_waba_webhook)
          expect { service.perform }.not_to raise_error
        end
      end
    end

    context 'when webhook setup fails' do
      before do
        allow(GlobalConfigService).to receive(:load)
          .with('WHATSAPP_FEATURE_TYPE', '').and_return('')
        allow(SecureRandom).to receive(:random_number).with(900_000).and_return(123_456)
        allow(service).to receive(:coexistence_method?).and_return(false)
        allow(api_client).to receive(:register_phone_number)
        allow(api_client).to receive(:subscribe_waba_webhook).and_raise('Webhook failed')
      end

      it 'raises an error' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect { service.perform }.to raise_error(/Webhook setup failed/)
        end
      end
    end

    context 'when required parameters are missing' do
      it 'raises error when channel is nil' do
        service_invalid = described_class.new(nil, waba_id, access_token)
        expect { service_invalid.perform }.to raise_error(ArgumentError, 'Channel is required')
      end

      it 'raises error when waba_id is blank' do
        service_invalid = described_class.new(channel, '', access_token)
        expect { service_invalid.perform }.to raise_error(ArgumentError, 'WABA ID is required')
      end

      it 'raises error when access_token is blank' do
        service_invalid = described_class.new(channel, waba_id, '')
        expect { service_invalid.perform }.to raise_error(ArgumentError, 'Access token is required')
      end
    end

    context 'when PIN already exists' do
      before do
        channel.provider_config['verification_pin'] = 123_456
        allow(GlobalConfigService).to receive(:load)
          .with('WHATSAPP_FEATURE_TYPE', '').and_return('')
        allow(service).to receive(:coexistence_method?).and_return(false)
        allow(api_client).to receive(:register_phone_number)
        allow(api_client).to receive(:subscribe_waba_webhook).and_return({ 'success' => true })
        allow(channel).to receive(:save!)
      end

      it 'reuses existing PIN' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number).with('123456789', 123_456)
          expect(SecureRandom).not_to receive(:random_number)
          service.perform
        end
      end
    end

    context 'when using coexistence method and phone is already verified' do
      before do
        allow(service).to receive(:coexistence_method?).and_return(true)
        allow(api_client).to receive(:subscribe_waba_webhook).and_return({ 'success' => true })
      end

      it 'skips phone registration and only subscribes webhook' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).not_to receive(:register_phone_number)
          expect(api_client).to receive(:subscribe_waba_webhook)
          service.perform
        end
      end
    end

    context 'when using coexistence method and phone is NOT verified' do
      before do
        allow(service).to receive(:coexistence_method?).and_return(false)
        allow(api_client).to receive(:register_phone_number)
        allow(api_client).to receive(:subscribe_waba_webhook).and_return({ 'success' => true })
        allow(channel).to receive(:save!)
      end

      it 'registers phone then subscribes webhook' do
        with_modified_env FRONTEND_URL: 'https://app.chatwoot.com' do
          expect(api_client).to receive(:register_phone_number)
          expect(api_client).to receive(:subscribe_waba_webhook)
          service.perform
        end
      end
    end
  end

  describe '#coexistence_method?' do
    let(:service_with_api_client) { described_class.new(channel, waba_id, access_token) }

    it 'returns false when WHATSAPP_FEATURE_TYPE is blank' do
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_FEATURE_TYPE', '').and_return('')
      expect(service_with_api_client.send(:coexistence_method?)).to be(false)
    end

    it 'returns false when phone is not verified' do
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_FEATURE_TYPE', '').and_return('whatsapp_business_app_onboarding')
      allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(false)
      expect(service_with_api_client.send(:coexistence_method?)).to be(false)
    end

    it 'returns true when feature flag and phone is verified' do
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_FEATURE_TYPE', '').and_return('whatsapp_business_app_onboarding')
      allow(api_client).to receive(:phone_number_verified?).with('123456789').and_return(true)
      expect(service_with_api_client.send(:coexistence_method?)).to be(true)
    end

    it 'rescues and returns false when phone_number_verified? raises' do
      allow(GlobalConfigService).to receive(:load).with('WHATSAPP_FEATURE_TYPE', '').and_return('whatsapp_business_app_onboarding')
      allow(api_client).to receive(:phone_number_verified?).with('123456789').and_raise('any error')
      expect(service_with_api_client.send(:coexistence_method?)).to be(false)
    end
  end
end
