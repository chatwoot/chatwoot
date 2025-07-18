require 'rails_helper'

RSpec.describe Whatsapp::ReauthorizationService do
  let(:account) { create(:account) }
  let(:whatsapp_channel) do
    channel = build(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                       provider_config: {
                                         'api_key' => 'old_token',
                                         'phone_number_id' => '123456',
                                         'business_account_id' => '654321',
                                         'source' => 'embedded_signup'
                                       })
    allow(channel).to receive(:validate_provider_config).and_return(true)
    allow(channel).to receive(:sync_templates).and_return(true)
    allow(channel).to receive(:setup_webhooks).and_return(true)
    channel.save!
    channel
  end
  let(:inbox) { create(:inbox, channel: whatsapp_channel, account: account) }

  let(:service) do
    described_class.new(
      inbox: inbox,
      code: 'auth_code_123',
      business_id: 'business_123',
      waba_id: 'waba_123',
      phone_number_id: 'phone_123'
    )
  end

  describe '#perform' do
    context 'when channel is embedded signup WhatsApp' do
      let(:access_token) { 'new_access_token' }
      let(:phone_info) { { phone_number: "+9999#{rand(100_000..999_999)}", verified_name: 'Test Business' } }

      before do
        # Mock the service dependencies to return expected values
        token_service = instance_double(Whatsapp::TokenExchangeService)
        allow(Whatsapp::TokenExchangeService).to receive(:new).with('auth_code_123').and_return(token_service)
        allow(token_service).to receive(:perform).and_return({ access_token: access_token })

        validation_service = instance_double(Whatsapp::TokenValidationService)
        allow(Whatsapp::TokenValidationService).to receive(:new).with(
          access_token, 'waba_123'
        ).and_return(validation_service)
        allow(validation_service).to receive(:perform).and_return({ valid: true })

        phone_service = instance_double(Whatsapp::PhoneInfoService)
        allow(Whatsapp::PhoneInfoService).to receive(:new).with(
          'waba_123', 'phone_123', access_token
        ).and_return(phone_service)
        allow(phone_service).to receive(:perform).and_return({
                                                               phone_number: phone_info[:phone_number],
                                                               verified_name: phone_info[:verified_name]
                                                             })

        webhook_service = instance_double(Whatsapp::WebhookSetupService)
        allow(Whatsapp::WebhookSetupService).to receive(:new).with(
          whatsapp_channel,
          'business_123',
          access_token
        ).and_return(webhook_service)
        allow(webhook_service).to receive(:perform).and_return({ success: true })
      end

      it 'successfully reauthorizes the channel' do
        result = service.perform

        expect(result[:success]).to be true
        whatsapp_channel.reload
        expect(whatsapp_channel.provider_config['api_key']).to eq(access_token)
        expect(whatsapp_channel.phone_number).to eq(phone_info[:phone_number])
      end

      it 'marks the channel as reauthorized' do
        # Set up the channel as requiring reauthorization
        whatsapp_channel.authorization_error!
        whatsapp_channel.authorization_error!
        expect(whatsapp_channel.reauthorization_required?).to be true

        service.perform

        # Check that reauthorization is no longer required
        expect(whatsapp_channel.reauthorization_required?).to be false
      end

      it 'updates channel configuration with new values' do
        service.perform

        updated_config = whatsapp_channel.reload.provider_config
        expect(updated_config['api_key']).to eq(access_token)
        expect(updated_config['phone_number_id']).to eq('phone_123')
        expect(updated_config['business_account_id']).to eq('business_123')
      end

      context 'when token exchange fails' do
        before do
          token_service = instance_double(Whatsapp::TokenExchangeService)
          allow(Whatsapp::TokenExchangeService).to receive(:new).with('auth_code_123').and_return(token_service)
          allow(token_service).to receive(:perform).and_return({})
        end

        it 'returns failure response' do
          result = service.perform

          expect(result[:success]).to be false
          expect(result[:message]).to eq('Failed to exchange code for access token. Please try again.')
        end
      end

      context 'when token validation fails' do
        before do
          token_service = instance_double(Whatsapp::TokenExchangeService)
          allow(Whatsapp::TokenExchangeService).to receive(:new).with('auth_code_123').and_return(token_service)
          allow(token_service).to receive(:perform).and_return({ access_token: access_token })

          validation_service = instance_double(Whatsapp::TokenValidationService)
          allow(Whatsapp::TokenValidationService).to receive(:new).with(
            access_token, 'waba_123'
          ).and_return(validation_service)
          allow(validation_service).to receive(:perform).and_return({ valid: false })
        end

        it 'returns failure response' do
          result = service.perform

          expect(result[:success]).to be false
          expect(result[:message]).to eq('The access token does not have the required permissions for WhatsApp.')
        end
      end

      context 'when phone info fetch fails' do
        before do
          token_service = instance_double(Whatsapp::TokenExchangeService)
          allow(Whatsapp::TokenExchangeService).to receive(:new).with('auth_code_123').and_return(token_service)
          allow(token_service).to receive(:perform).and_return({ access_token: access_token })

          validation_service = instance_double(Whatsapp::TokenValidationService)
          allow(Whatsapp::TokenValidationService).to receive(:new).with(
            access_token, 'waba_123'
          ).and_return(validation_service)
          allow(validation_service).to receive(:perform).and_return({ valid: true })

          phone_service = instance_double(Whatsapp::PhoneInfoService)
          allow(Whatsapp::PhoneInfoService).to receive(:new).with(
            'waba_123', 'phone_123', access_token
          ).and_return(phone_service)
          allow(phone_service).to receive(:perform).and_return({})
        end

        it 'returns failure response' do
          result = service.perform

          expect(result[:success]).to be false
          expect(result[:message]).to eq('Failed to fetch phone number information. Please try again.')
        end
      end

      context 'when webhook setup fails' do
        before do
          webhook_service = instance_double(Whatsapp::WebhookSetupService)
          allow(Whatsapp::WebhookSetupService).to receive(:new).with(
            whatsapp_channel,
            'business_123',
            access_token
          ).and_return(webhook_service)
          allow(webhook_service).to receive(:perform).and_raise(StandardError, 'Webhook error')
        end

        it 'does not fail the reauthorization' do
          result = service.perform

          expect(result[:success]).to be true
        end
      end
    end

    context 'when channel is not embedded signup' do
      let(:manual_channel) do
        channel = build(:channel_whatsapp, account: account, provider: 'whatsapp_cloud',
                                           provider_config: { 'api_key' => 'manual_token' })
        allow(channel).to receive(:validate_provider_config).and_return(true)
        allow(channel).to receive(:sync_templates).and_return(true)
        allow(channel).to receive(:setup_webhooks).and_return(true)
        channel.save!
        channel
      end
      let(:manual_inbox) { create(:inbox, channel: manual_channel, account: account) }
      let(:manual_service) do
        described_class.new(
          inbox: manual_inbox,
          code: 'auth_code',
          business_id: 'business_id',
          waba_id: 'waba_id',
          phone_number_id: 'phone_id'
        )
      end

      it 'returns not supported error' do
        result = manual_service.perform

        expect(result[:success]).to be false
        expect(result[:message]).to include('not supported')
      end
    end

    context 'when channel is not WhatsApp cloud' do
      let(:default_channel) do
        channel = build(:channel_whatsapp, account: account, provider: 'default')
        allow(channel).to receive(:validate_provider_config).and_return(true)
        allow(channel).to receive(:sync_templates).and_return(true)
        allow(channel).to receive(:setup_webhooks).and_return(true)
        channel.save!
        channel
      end
      let(:default_inbox) { create(:inbox, channel: default_channel, account: account) }
      let(:default_service) do
        described_class.new(
          inbox: default_inbox,
          code: 'auth_code',
          business_id: 'business_id',
          waba_id: 'waba_id',
          phone_number_id: 'phone_id'
        )
      end

      it 'returns not supported error' do
        result = default_service.perform

        expect(result[:success]).to be false
        expect(result[:message]).to include('not supported')
      end
    end

    context 'when unexpected error occurs' do
      before do
        # Ensure the channel is embedded signup
        allow(service).to receive(:embedded_signup_channel?).and_return(true)

        # Mock token service to raise error
        allow(Whatsapp::TokenExchangeService).to receive(:new).and_raise(StandardError, 'Unexpected error')
      end

      it 'returns generic error message' do
        result = service.perform

        expect(result[:success]).to be false
        expect(result[:message]).to include('try again')
      end
    end
  end
end
