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
  let(:channel) do
    create(:channel_whatsapp, account: account, phone_number: '+15550000001',
                              validate_provider_config: false, sync_templates: false)
  end

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

      channel_creation = instance_double(Whatsapp::ChannelCreationService)
      allow(Whatsapp::ChannelCreationService).to receive(:new)
        .with(account, { waba_id: params[:waba_id], business_name: 'Test Business' }, phone_info, access_token)
        .and_return(channel_creation)
      allow(channel_creation).to receive(:perform).and_return(channel)
    end

    it 'creates the channel and enqueues webhook setup with the health check' do
      expect { service.perform }
        .to have_enqueued_job(Channels::Whatsapp::WebhookSetupJob).with(channel, run_health_check: true)
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
          waba_id: params[:waba_id]
        ).and_return(reauth_service)
        allow(reauth_service).to receive(:perform).with(access_token, phone_info).and_return(channel)

        health_service = instance_double(Whatsapp::HealthService)
        allow(Whatsapp::HealthService).to receive(:new).and_return(health_service)
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'CLOUD_API',
                                                                            throughput: { 'level' => 'STANDARD' },
                                                                            messaging_limit_tier: 'TIER_1000'
                                                                          })
      end

      it 'uses ReauthorizationService and enqueues webhook setup without the health check' do
        expect(reauth_service).to receive(:perform)

        expect { service_with_inbox.perform }
          .to have_enqueued_job(Channels::Whatsapp::WebhookSetupJob).with(channel, run_health_check: false)
      end

      context 'with real channel requiring reauthorization' do
        let(:inbox) { create(:inbox, account: account) }
        let(:whatsapp_channel) do
          create(:channel_whatsapp, account: account, phone_number: '+1234567890',
                                    validate_provider_config: false, sync_templates: false)
        end
        let(:service_with_real_inbox) { described_class.new(account: account, params: params, inbox_id: inbox.id) }

        before do
          inbox.update!(channel: whatsapp_channel)
          whatsapp_channel.prompt_reauthorization!

          setup_reauthorization_mocks
          setup_health_service_mock
        end

        it 'clears reauthorization flag when reauthorization completes' do
          expect(whatsapp_channel.reauthorization_required?).to be true
          result = service_with_real_inbox.perform
          expect(result).to eq(whatsapp_channel)
          expect(whatsapp_channel.reauthorization_required?).to be false
        end

        private

        def setup_reauthorization_mocks
          reauth_service = instance_double(Whatsapp::ReauthorizationService)
          allow(Whatsapp::ReauthorizationService).to receive(:new).with(
            account: account,
            inbox_id: inbox.id,
            phone_number_id: params[:phone_number_id],
            waba_id: params[:waba_id]
          ).and_return(reauth_service)

          allow(reauth_service).to receive(:perform) do
            whatsapp_channel.reauthorized!
            whatsapp_channel
          end

          allow(whatsapp_channel).to receive(:setup_webhooks).and_return(true)
        end

        def setup_health_service_mock
          health_service = instance_double(Whatsapp::HealthService)
          allow(Whatsapp::HealthService).to receive(:new).and_return(health_service)
          allow(health_service).to receive(:fetch_health_status).and_return({
                                                                              platform_type: 'CLOUD_API',
                                                                              throughput: { 'level' => 'STANDARD' },
                                                                              messaging_limit_tier: 'TIER_1000'
                                                                            })
        end
      end
    end
  end
end
