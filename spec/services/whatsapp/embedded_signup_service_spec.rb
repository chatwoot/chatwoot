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
        .with(params[:waba_id], params[:phone_number_id], access_token, expected_phone_number: anything).and_return(phone_service)
      allow(phone_service).to receive(:perform).and_return(phone_info)

      channel_creation = instance_double(Whatsapp::ChannelCreationService)
      allow(Whatsapp::ChannelCreationService).to receive(:new)
        .with(account, { waba_id: params[:waba_id], business_name: 'Test Business' }, phone_info, access_token)
        .and_return(channel_creation)
      allow(channel_creation).to receive(:perform).and_return(channel)

      allow(channel).to receive(:setup_webhooks)
      allow(channel).to receive(:phone_number).and_return('+1234567890')

      health_service = instance_double(Whatsapp::HealthService)
      allow(Whatsapp::HealthService).to receive(:new).and_return(health_service)
      allow(health_service).to receive(:fetch_health_status).and_return({
                                                                          platform_type: 'CLOUD_API',
                                                                          throughput: { 'level' => 'STANDARD' },
                                                                          messaging_limit_tier: 'TIER_1000'
                                                                        })
    end

    it 'creates channel and sets up webhooks' do
      expect(channel).to receive(:setup_webhooks)

      result = service.perform
      expect(result).to eq(channel)
    end

    it 'checks health status after channel creation' do
      health_service = instance_double(Whatsapp::HealthService)
      allow(Whatsapp::HealthService).to receive(:new).and_return(health_service)
      expect(health_service).to receive(:fetch_health_status)

      service.perform
    end

    context 'when channel is in pending state' do
      it 'prompts reauthorization for pending channel' do
        health_service = instance_double(Whatsapp::HealthService)
        allow(Whatsapp::HealthService).to receive(:new).and_return(health_service)
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'NOT_APPLICABLE',
                                                                            throughput: { 'level' => 'STANDARD' },
                                                                            messaging_limit_tier: 'TIER_1000'
                                                                          })

        expect(channel).to receive(:prompt_reauthorization!)
        service.perform
      end

      it 'prompts reauthorization when throughput level is NOT_APPLICABLE' do
        health_service = instance_double(Whatsapp::HealthService)
        allow(Whatsapp::HealthService).to receive(:new).and_return(health_service)
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'CLOUD_API',
                                                                            throughput: { 'level' => 'NOT_APPLICABLE' },
                                                                            messaging_limit_tier: 'TIER_1000'
                                                                          })

        expect(channel).to receive(:prompt_reauthorization!)
        service.perform
      end
    end

    context 'when channel is healthy' do
      it 'does not prompt reauthorization for healthy channel' do
        expect(channel).not_to receive(:prompt_reauthorization!)
        service.perform
      end
    end

    context 'when parameters are invalid' do
      it 'raises ArgumentError for missing parameters' do
        invalid_service = described_class.new(account: account, params: { code: '', waba_id: '' })
        expect { invalid_service.perform }.to raise_error(ArgumentError, 'Required parameters are missing: code, waba_id')
      end

      it 'does not require business_id' do
        coexistence_service = described_class.new(account: account, params: params.except(:business_id))
        expect { coexistence_service.perform }.not_to raise_error
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

      # Signup is where a wrong token is most likely, so the failure that says so has to arrive.
      # What it must not do is answer for the failures that say nothing about the token: the service
      # completes either way, and the difference is whether the operator is sent to fix a credential.
      def channel_whose_setup_raises(error)
        real_channel = create(:channel_whatsapp, account: account, phone_number: '+1234567890',
                                                 validate_provider_config: false, sync_templates: false)
        channel_creation = instance_double(Whatsapp::ChannelCreationService)
        allow(Whatsapp::ChannelCreationService).to receive(:new).and_return(channel_creation)
        allow(channel_creation).to receive(:perform).and_return(real_channel)
        allow(real_channel).to receive(:perform_webhook_setup).and_raise(error)
        real_channel
      end

      it 'prompts reauthorization when Meta says the token is the problem' do
        refused = Whatsapp::ApiError.new(message: 'App subscription to WABA failed', http_status: 401, code: 190)
        real_channel = channel_whose_setup_raises(refused)

        expect(real_channel.reauthorization_required?).to be false

        expect(service.perform).to eq(real_channel)
        expect(real_channel.reauthorization_required?).to be true
      end

      it 'leaves the channel alone when the webhook setup failed without an answer from Meta' do
        real_channel = channel_whose_setup_raises(Net::ReadTimeout.new)

        expect(service.perform).to eq(real_channel)
        expect(real_channel.reauthorization_required?).to be false
      end
    end

    context 'with provider conversion flow' do
      let(:baileys_channel) do
        create(:channel_whatsapp, account: account, provider: 'baileys', phone_number: '+1234567890',
                                  validate_provider_config: false, sync_templates: false)
      end
      let(:baileys_inbox) { baileys_channel.inbox }
      let(:service_with_inbox) do
        described_class.new(account: account, params: params, inbox_id: baileys_inbox.id)
      end

      before do
        # The service does `@account.inboxes.find(id).channel`; force the chain
        # to return the same Ruby instances the test sets expectations on so
        # the message expectations actually match.
        # Materialize the factory records before doubling `account.inboxes` —
        # inbox creation runs Enterprise's Inbox#ensure_create_permitted, which
        # counts inboxes through the real association.
        baileys_inbox

        inbox_relation = instance_double(ActiveRecord::Relation)
        allow(account).to receive(:inboxes).and_return(inbox_relation)
        allow(inbox_relation).to receive(:find).with(baileys_inbox.id).and_return(baileys_inbox)
        allow(baileys_inbox).to receive(:channel).and_return(baileys_channel)

        allow(baileys_channel).to receive(:convert_provider!).and_return(baileys_channel)
        allow(baileys_channel).to receive(:setup_webhooks)
      end

      it 'routes to convert_provider! with embedded signup credentials' do
        expect(baileys_channel).to receive(:convert_provider!).with(
          new_provider: 'whatsapp_cloud',
          new_provider_config: {
            'api_key' => access_token,
            'phone_number_id' => params[:phone_number_id],
            'business_account_id' => params[:waba_id],
            'source' => 'embedded_signup'
          }
        ).and_return(baileys_channel)

        expect(baileys_channel).to receive(:setup_webhooks)

        result = service_with_inbox.perform
        expect(result).to eq(baileys_channel)
      end

      it 'stores the waba_id (not the meta business_id) in business_account_id' do
        captured_config = nil
        allow(baileys_channel).to receive(:convert_provider!) do |args|
          captured_config = args[:new_provider_config]
          baileys_channel
        end

        service_with_inbox.perform

        expect(captured_config['business_account_id']).to eq(params[:waba_id])
        expect(captured_config['business_account_id']).not_to eq(params[:business_id])
      end

      it 'skips ReauthorizationService when current provider is not whatsapp_cloud' do
        expect(Whatsapp::ReauthorizationService).not_to receive(:new)
        service_with_inbox.perform
      end

      it 'does not run channel health check on conversion' do
        expect(Whatsapp::HealthService).not_to receive(:new)
        service_with_inbox.perform
      end
    end

    context 'with reauthorization flow' do
      let(:inbox_id) { 123 }
      let(:cloud_inbox) { instance_double(Inbox) }
      let(:cloud_channel) { instance_double(Channel::Whatsapp, provider: 'whatsapp_cloud', phone_number: '+1234567890') }
      let(:reauth_service) { instance_double(Whatsapp::ReauthorizationService) }
      let(:service_with_inbox) do
        described_class.new(account: account, params: params, inbox_id: inbox_id)
      end

      before do
        # The service looks up the channel before routing; stub the lookup chain
        # so it returns a whatsapp_cloud channel and routes to ReauthorizationService.
        inbox_relation = instance_double(ActiveRecord::Relation)
        allow(account).to receive(:inboxes).and_return(inbox_relation)
        allow(inbox_relation).to receive(:find).with(inbox_id).and_return(cloud_inbox)
        allow(cloud_inbox).to receive(:channel).and_return(cloud_channel)

        allow(Whatsapp::ReauthorizationService).to receive(:new).with(
          account: account,
          inbox_id: inbox_id,
          phone_number_id: params[:phone_number_id],
          waba_id: params[:waba_id]
        ).and_return(reauth_service)
        allow(reauth_service).to receive(:perform).with(access_token, phone_info).and_return(channel)

        allow(channel).to receive(:phone_number).and_return('+1234567890')

        health_service = instance_double(Whatsapp::HealthService)
        allow(Whatsapp::HealthService).to receive(:new).and_return(health_service)
        allow(health_service).to receive(:fetch_health_status).and_return({
                                                                            platform_type: 'CLOUD_API',
                                                                            throughput: { 'level' => 'STANDARD' },
                                                                            messaging_limit_tier: 'TIER_1000'
                                                                          })
      end

      it 'uses ReauthorizationService and sets up webhooks' do
        expect(reauth_service).to receive(:perform)
        expect(channel).to receive(:setup_webhooks)

        result = service_with_inbox.perform
        expect(result).to eq(channel)
      end

      context 'with real channel requiring reauthorization' do
        let(:inbox) { create(:inbox, account: account) }
        let(:whatsapp_channel) do
          create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', phone_number: '+1234567890',
                                    validate_provider_config: false, sync_templates: false)
        end
        let(:service_with_real_inbox) { described_class.new(account: account, params: params, inbox_id: inbox.id) }

        before do
          # Reset the outer context's account.inboxes stub so the real lookup runs
          # against the persisted inbox created here.
          allow(account).to receive(:inboxes).and_call_original

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
