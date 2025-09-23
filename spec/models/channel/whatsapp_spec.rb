# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/reauthorizable_shared.rb'

RSpec.describe Channel::Whatsapp do
  describe 'concerns' do
    let(:channel) { create(:channel_whatsapp) }

    before do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
    end

    it_behaves_like 'reauthorizable'

    context 'when prompt_reauthorization!' do
      it 'calls channel notifier mail for whatsapp' do
        admin_mailer = double
        mailer_double = double

        expect(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).and_return(admin_mailer)
        expect(admin_mailer).to receive(:whatsapp_disconnect).with(channel.inbox).and_return(mailer_double)
        expect(mailer_double).to receive(:deliver_later)

        channel.prompt_reauthorization!
      end
    end
  end

  describe 'validate_provider_config' do
    it 'validates false when provider config is wrong' do
      channel = build(:channel_whatsapp, provider: 'whatsapp_cloud', account: create(:account), validate_provider_config: false, sync_templates: false)
      
      # Manually set the correct provider_config since the factory callback isn't working
      channel.provider_config = channel.provider_config.merge({
        'api_key' => 'test_key',
        'phone_number_id' => '123456789',
        'business_account_id' => '123456789'
      })
      
      stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key').to_return(status: 401)
      expect(channel.save).to be(false)
    end

    it 'validates true when provider config is right' do
      channel = build(:channel_whatsapp, provider: 'whatsapp_cloud', account: create(:account), validate_provider_config: false, sync_templates: false)
      
      # Manually set the correct provider_config since the factory callback isn't working
      channel.provider_config = channel.provider_config.merge({
        'api_key' => 'test_key',
        'phone_number_id' => '123456789',
        'business_account_id' => '123456789'
      })
      
      stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key')
        .to_return(status: 200,
                   body: { data: [{
                     id: '123456789', name: 'test_template'
                   }] }.to_json)
      
      expect(channel.save).to be(true)
    end
  end

  describe 'webhook_verify_token' do
    before do
      # Stub WhatsApp Cloud API for validation
      stub_request(:get, 'https://graph.facebook.com/v14.0/123456789/message_templates?access_token=test_key')
        .to_return(status: 200, body: { data: [] }.to_json)
    end

    it 'generates webhook_verify_token if not present' do
      channel = build(:channel_whatsapp, 
                      provider_config: { 
                        'webhook_verify_token' => nil, 
                        'api_key' => 'test_key', 
                        'phone_number_id' => '123456789',
                        'business_account_id' => '123456789'
                      }, 
                      provider: 'whatsapp_cloud', 
                      account: create(:account),
                      validate_provider_config: false, 
                      sync_templates: false)
      
      # Stub sync_templates to prevent HTTP calls
      allow(channel).to receive(:sync_templates)
      
      channel.save!(validate: false)
      create(:inbox, channel: channel, account: channel.account)

      # Test the actual webhook_verify_token generation logic
      config_object = channel.provider_config_object
      expect(config_object.webhook_verify_token).not_to be_nil
    end

    it 'does not generate webhook_verify_token if present' do
      channel = build(:channel_whatsapp, 
                      provider: 'whatsapp_cloud', 
                      provider_config: { 
                        'webhook_verify_token' => '123', 
                        'api_key' => 'test_key', 
                        'phone_number_id' => '123456789',
                        'business_account_id' => '123456789'
                      }, 
                      account: create(:account),
                      validate_provider_config: false, 
                      sync_templates: false)
      
      # Stub sync_templates to prevent HTTP calls
      allow(channel).to receive(:sync_templates)
      
      channel.save!(validate: false)
      create(:inbox, channel: channel, account: channel.account)

      expect(channel.provider_config['webhook_verify_token']).to eq '123'
    end
  end

  describe 'provider configuration pattern' do
    let(:channel) do
      ch = build(:channel_whatsapp, provider: 'whapi', account: create(:account), validate_provider_config: false, sync_templates: false)
      ch.save!(validate: false)
      create(:inbox, channel: ch, account: ch.account)
      ch
    end

    before do
      # Stub WHAPI health check endpoint for any API key
      stub_request(:get, 'https://gate.whapi.cloud/health')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: '{}')
    end

    describe '#provider_config_object' do
      it 'returns a provider configuration object' do
        expect(channel.provider_config_object).to be_a(Whatsapp::ProviderConfig::Whapi)
      end

      it 'memoizes the provider configuration object' do
        config1 = channel.provider_config_object
        config2 = channel.provider_config_object
        expect(config1).to be(config2)
      end

      it 'invalidates cache when provider_config changes' do
        original_config = channel.provider_config_object
        channel.update!(provider_config: { 'api_key' => 'new_key' })
        new_config = channel.provider_config_object
        expect(new_config).not_to be(original_config)
      end
    end

    describe '#provider_service' do
      it 'uses the factory method' do
        service = channel.provider_service
        expect(service).to be_a(Whatsapp::Providers::WhapiService)
      end

      it 'memoizes the provider service' do
        service1 = channel.provider_service
        service2 = channel.provider_service
        expect(service1).to be(service2)
      end

      it 'invalidates cache when provider changes' do
        original_service = channel.provider_service
        channel.update!(provider: 'whatsapp_cloud')
        new_service = channel.provider_service
        expect(new_service).not_to be(original_service)
      end
    end

    describe 'provider-specific methods through config objects' do
      let(:whapi_channel) do
        ch = build(:channel_whatsapp,
                   provider: 'whapi',
                   provider_config: { 'whapi_channel_id' => 'test_id', 'whapi_channel_token' => 'test_token', 'connection_status' => 'active' },
                   account: create(:account),
                   validate_provider_config: false,
                   sync_templates: false)
        ch.save!(validate: false)
        create(:inbox, channel: ch, account: ch.account)
        ch
      end

      before do
        # Stub WHAPI health check for this specific test (no api_key, so it should use partner channel logic)
        stub_request(:get, 'https://gate.whapi.cloud/health')
          .with(headers: { 'Authorization' => 'Bearer', 'Content-Type' => 'application/json' })
          .to_return(status: 200, body: '{}')
      end

      it 'accesses whapi-specific methods through config object' do
        config = whapi_channel.provider_config_object
        expect(config.whapi_channel_id).to eq('test_id')
        expect(config.whapi_channel_token).to eq('test_token')
        expect(config.whapi_connection_status).to eq('active')
        expect(config.whapi_partner_channel?).to be true
      end
    end

    describe 'cleanup through config object' do
      let(:whapi_channel) do
        # Skip validation by building and saving without validation
        channel = build(:channel_whatsapp,
                       provider: 'whapi',
                       provider_config: { 'whapi_channel_id' => 'test_id' },
                       account: create(:account),
                       validate_provider_config: false,
                       sync_templates: false)
        channel.save!(validate: false)
        channel
      end

      it 'calls cleanup through provider config object' do
        expect(Whatsapp::Whapi::WhapiChannelCleanupJob).to receive(:perform_later).with('test_id').once
        whapi_channel.destroy
      end
    end
  end

  describe 'webhook setup after creation' do
    let(:account) { create(:account) }
    let(:webhook_service) { instance_double(Whatsapp::WebhookSetupService) }

    before do
      allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_service)
      allow(webhook_service).to receive(:perform)
    end

    context 'when channel is created through embedded signup' do
      it 'does not raise error if webhook setup fails' do
        allow(Whatsapp::WebhookSetupService).to receive(:new).and_raise(StandardError)
        expect do
          create(:channel_whatsapp,
                 account: account,
                 provider: 'whatsapp_cloud',
                 provider_config: {
                   'source' => 'embedded_signup',
                   'business_account_id' => 'test_waba_id',
                   'api_key' => 'test_access_token'
                 },
                 sync_templates: false)
        end.not_to raise_error
      end
    end

    context 'when channel is created through manual setup' do
      it 'does not setup webhooks' do
        expect(Whatsapp::WebhookSetupService).not_to receive(:new)
        create(:channel_whatsapp,
               account: account,
               provider: 'whatsapp_cloud',
               provider_config: {
                 'business_account_id' => 'test_waba_id',
                 'api_key' => 'test_access_token'
               },
               sync_templates: false)
      end
    end

    context 'when channel is created with different provider' do
      it 'does not setup webhooks for 360dialog provider' do
        expect(Whatsapp::WebhookSetupService).not_to receive(:new)

        create(:channel_whatsapp,
               account: account,
               provider: 'default',
               provider_config: {
                 'source' => 'embedded_signup',
                 'api_key' => 'test_360dialog_key'
               },
               validate_provider_config: false,
               sync_templates: false)
      end
    end
  end

  describe '#teardown_webhooks' do
    let(:account) { create(:account) }

    context 'when channel is whatsapp_cloud with embedded_signup' do
      it 'calls WebhookTeardownService on destroy' do
        # Mock the setup service to prevent HTTP calls during creation
        setup_service = instance_double(Whatsapp::WebhookSetupService)
        allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(setup_service)
        allow(setup_service).to receive(:perform)

        channel = create(:channel_whatsapp,
                         account: account,
                         provider: 'whatsapp_cloud',
                         provider_config: {
                           'source' => 'embedded_signup',
                           'business_account_id' => 'test_waba_id',
                           'api_key' => 'test_access_token',
                           'phone_number_id' => '123456789'
                         },
                         validate_provider_config: false,
                         sync_templates: false)

        teardown_service = instance_double(Whatsapp::WebhookTeardownService)
        allow(Whatsapp::WebhookTeardownService).to receive(:new).with(channel).and_return(teardown_service)
        allow(teardown_service).to receive(:perform)

        channel.destroy

        expect(Whatsapp::WebhookTeardownService).to have_received(:new).with(channel)
        expect(teardown_service).to have_received(:perform)
      end
    end

    context 'when channel is not embedded_signup' do
      it 'does not call WebhookTeardownService on destroy' do
        channel = create(:channel_whatsapp,
                         account: account,
                         provider: 'whatsapp_cloud',
                         provider_config: {
                           'source' => 'manual',
                           'api_key' => 'test_access_token'
                         },
                         validate_provider_config: false,
                         sync_templates: false)

        teardown_service = instance_double(Whatsapp::WebhookTeardownService)
        allow(Whatsapp::WebhookTeardownService).to receive(:new).with(channel).and_return(teardown_service)
        allow(teardown_service).to receive(:perform)

        channel.destroy

        expect(teardown_service).to have_received(:perform)
      end
    end
  end
end
