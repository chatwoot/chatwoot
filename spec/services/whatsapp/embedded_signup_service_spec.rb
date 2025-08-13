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
  let(:service) { described_class.new(account: account, params: params) }
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

  describe '#perform' do
    before do
      allow(GlobalConfig).to receive(:clear_cache)

      # Mock service dependencies
      token_exchange = instance_double(Whatsapp::TokenExchangeService)
      allow(Whatsapp::TokenExchangeService).to receive(:new).with(params[:code]).and_return(token_exchange)
      allow(token_exchange).to receive(:perform).and_return(access_token)

      phone_service = instance_double(Whatsapp::PhoneInfoService)
      allow(Whatsapp::PhoneInfoService).to receive(:new)
        .with(params[:waba_id], params[:phone_number_id], access_token).and_return(phone_service)
      allow(phone_service).to receive(:perform).and_return(phone_info)

      validation_service = instance_double(Whatsapp::TokenValidationService)
      allow(Whatsapp::TokenValidationService).to receive(:new)
        .with(access_token, params[:waba_id]).and_return(validation_service)
      allow(validation_service).to receive(:perform)

      channel_creation = instance_double(Whatsapp::ChannelCreationService)
      allow(Whatsapp::ChannelCreationService).to receive(:new)
        .with(account, { waba_id: params[:waba_id], business_name: 'Test Business' }, phone_info, access_token)
        .and_return(channel_creation)
      allow(channel_creation).to receive(:perform).and_return(channel)

      allow(channel).to receive(:setup_webhooks)
    end

    it 'creates channel and sets up webhooks' do
      expect(channel).to receive(:setup_webhooks)

      result = service.perform
      expect(result).to eq(channel)
    end

    context 'when parameters are invalid' do
      it 'raises ArgumentError for missing parameters' do
        invalid_service = described_class.new(account: account, params: { code: '', business_id: '', waba_id: '' })
        expect { invalid_service.perform }.to raise_error(ArgumentError, /Required parameters are missing/)
      end
    end

    context 'when service fails' do
      it 'logs and re-raises errors' do
        token_exchange = instance_double(Whatsapp::TokenExchangeService)
        allow(Whatsapp::TokenExchangeService).to receive(:new).and_return(token_exchange)
        allow(token_exchange).to receive(:perform).and_raise('Token error')

        expect(Rails.logger).to receive(:error).with('[WHATSAPP] Embedded signup failed: Token error')
        expect { service.perform }.to raise_error('Token error')
      end

      it 'prompts reauthorization when webhook setup fails' do
        # Create a real channel to test the actual webhook failure behavior
        real_channel = create(:channel_whatsapp, account: account, phone_number: '+1234567890',
                                                 validate_provider_config: false, sync_templates: false)

        # Mock the channel creation to return our real channel
        channel_creation = instance_double(Whatsapp::ChannelCreationService)
        allow(Whatsapp::ChannelCreationService).to receive(:new).and_return(channel_creation)
        allow(channel_creation).to receive(:perform).and_return(real_channel)

        # Mock webhook setup to fail
        allow(real_channel).to receive(:perform_webhook_setup).and_raise('Webhook setup error')

        # Verify channel is not marked for reauthorization initially
        expect(real_channel.reauthorization_required?).to be false

        # The service completes successfully even if webhook fails (webhook error is rescued in setup_webhooks)
        result = service.perform
        expect(result).to eq(real_channel)

        # Verify the channel is now marked for reauthorization
        expect(real_channel.reauthorization_required?).to be true
      end
    end

    context 'with reauthorization flow' do
      let(:inbox_id) { 123 }
      let(:reauth_service) { instance_double(Whatsapp::ReauthorizationService) }
      let(:service_with_inbox) do
        described_class.new(account: account, params: params, inbox_id: inbox_id)
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

      it 'uses ReauthorizationService and sets up webhooks' do
        expect(reauth_service).to receive(:perform)
        expect(channel).to receive(:setup_webhooks)

        result = service_with_inbox.perform
        expect(result).to eq(channel)
      end

      it 'clears reauthorization flag' do
        inbox = create(:inbox, account: account)
        whatsapp_channel = create(:channel_whatsapp, account: account, phone_number: '+1234567890',
                                                     validate_provider_config: false, sync_templates: false)
        inbox.update!(channel: whatsapp_channel)
        whatsapp_channel.prompt_reauthorization!

        service_with_real_inbox = described_class.new(account: account, params: params, inbox_id: inbox.id)

        # Mock the ReauthorizationService to return our test channel
        reauth_service = instance_double(Whatsapp::ReauthorizationService)
        allow(Whatsapp::ReauthorizationService).to receive(:new).with(
          account: account,
          inbox_id: inbox.id,
          phone_number_id: params[:phone_number_id],
          business_id: params[:business_id]
        ).and_return(reauth_service)

        # Perform the reauthorization and clear the flag
        allow(reauth_service).to receive(:perform) do
          whatsapp_channel.reauthorized!
          whatsapp_channel
        end

        allow(whatsapp_channel).to receive(:setup_webhooks).and_return(true)

        expect(whatsapp_channel.reauthorization_required?).to be true
        result = service_with_real_inbox.perform
        expect(result).to eq(whatsapp_channel)
        expect(whatsapp_channel.reauthorization_required?).to be false
      end
    end
  end
end
