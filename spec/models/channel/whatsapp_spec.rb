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
    let(:channel) { build(:channel_whatsapp, provider: 'whatsapp_cloud', account: create(:account)) }

    it 'validates false when provider config is wrong' do
      stub_request(:get, 'https://graph.facebook.com/v14.0//message_templates?access_token=test_key').to_return(status: 401)
      expect(channel.save).to be(false)
    end

    it 'validates true when provider config is right' do
      stub_request(:get, 'https://graph.facebook.com/v14.0//message_templates?access_token=test_key')
        .to_return(status: 200,
                   body: { data: [{
                     id: '123456789', name: 'test_template'
                   }] }.to_json)
      expect(channel.save).to be(true)
    end
  end

  describe 'webhook_verify_token' do
    before do
      # Stub webhook setup to prevent HTTP calls during channel creation
      setup_service = instance_double(Whatsapp::WebhookSetupService)
      allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(setup_service)
      allow(setup_service).to receive(:perform)
    end

    it 'generates webhook_verify_token if not present' do
      channel = create(:channel_whatsapp,
                       provider_config: {
                         'webhook_verify_token' => nil,
                         'api_key' => 'test_key',
                         'business_account_id' => '123456789'
                       },
                       provider: 'whatsapp_cloud',
                       account: create(:account),
                       validate_provider_config: false,
                       sync_templates: false)

      expect(channel.provider_config['webhook_verify_token']).not_to be_nil
    end

    it 'does not generate webhook_verify_token if present' do
      channel = create(:channel_whatsapp,
                       provider: 'whatsapp_cloud',
                       provider_config: {
                         'webhook_verify_token' => '123',
                         'api_key' => 'test_key',
                         'business_account_id' => '123456789'
                       },
                       account: create(:account),
                       validate_provider_config: false,
                       sync_templates: false)

      expect(channel.provider_config['webhook_verify_token']).to eq '123'
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
        allow(webhook_service).to receive(:perform).and_raise(StandardError, 'Webhook error')

        expect do
          create(:channel_whatsapp,
                 account: account,
                 provider: 'whatsapp_cloud',
                 provider_config: {
                   'source' => 'embedded_signup',
                   'business_account_id' => 'test_waba_id',
                   'api_key' => 'test_access_token'
                 },
                 validate_provider_config: false,
                 sync_templates: false)
        end.not_to raise_error
      end
    end

    context 'when channel is created through manual setup' do
      it 'setups webhooks via after_commit callback' do
        expect(Whatsapp::WebhookSetupService).to receive(:new).and_return(webhook_service)
        expect(webhook_service).to receive(:perform)

        # Explicitly set source to nil to test manual setup behavior (not embedded_signup)
        create(:channel_whatsapp,
               account: account,
               provider: 'whatsapp_cloud',
               provider_config: {
                 'business_account_id' => 'test_waba_id',
                 'api_key' => 'test_access_token',
                 'source' => nil
               },
               validate_provider_config: false,
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

  # CUSTOMIZAÇÃO_SYNAPSEOS: ensure the agentic credential sync job is enqueued
  # whenever a WhatsApp channel is created/updated on a synapseos-linked
  # account, and is NOT enqueued when the only change is the credential id
  # write-back (loop guard).
  describe 'synapseos credential sync hook' do
    let(:linked_account) { create(:account, custom_attributes: { 'synapseos_agentic_slug' => 'royal_enfield' }) }
    let(:plain_account) { create(:account) }

    before do
      avisa_client = instance_double(Whatsapp::Providers::AvisaClient, register_webhook: true)
      allow(Whatsapp::Providers::AvisaClient).to receive(:new).and_return(avisa_client)
    end

    around do |example|
      with_modified_env(FRONTEND_URL: 'http://localhost:3000') { example.run }
    end

    it 'enqueues sync job when an avisa channel is created on a synapseos-linked account' do
      expect do
        create(:channel_whatsapp, account: linked_account, provider: 'avisa',
                                  provider_config: { 'api_key' => 'avisa_key', 'base_url' => 'https://www.avisaapi.com.br' },
                                  validate_provider_config: false, sync_templates: false)
      end.to have_enqueued_job(Synapseos::SyncWhatsappCredentialJob)
    end

    it 'still enqueues when the account is not linked to synapseos (job itself bails)' do
      expect do
        create(:channel_whatsapp, account: plain_account, provider: 'avisa',
                                  provider_config: { 'api_key' => 'avisa_key', 'base_url' => 'https://www.avisaapi.com.br' },
                                  validate_provider_config: false, sync_templates: false)
      end.to have_enqueued_job(Synapseos::SyncWhatsappCredentialJob)
      # NOTE: the hook fires regardless of slug — the job itself is the one that
      # bails when slug is blank. We assert this design here so future refactors
      # don't accidentally move the responsibility.
    end

    it 'does not re-enqueue when only synapseos_credential_id changes (loop guard)' do
      channel = create(:channel_whatsapp, account: linked_account, provider: 'avisa',
                                          provider_config: { 'api_key' => 'avisa_key', 'base_url' => 'https://www.avisaapi.com.br' },
                                          validate_provider_config: false, sync_templates: false)
      # Simulate the job's write-back through update_column (skips callbacks
      # entirely, but we also assert that even an update_columns through the
      # public API would not re-trigger because the secret keys didn't change).
      expect do
        new_config = channel.provider_config.merge('synapseos_credential_id' => 'cred_999')
        channel.update!(provider_config: new_config)
      end.not_to have_enqueued_job(Synapseos::SyncWhatsappCredentialJob)
    end

    it 'enqueues on update when api_key changes' do
      channel = create(:channel_whatsapp, account: linked_account, provider: 'avisa',
                                          provider_config: { 'api_key' => 'avisa_key', 'base_url' => 'https://www.avisaapi.com.br' },
                                          validate_provider_config: false, sync_templates: false)
      expect do
        channel.update!(provider_config: channel.provider_config.merge('api_key' => 'new_key'))
      end.to have_enqueued_job(Synapseos::SyncWhatsappCredentialJob).with(channel.id)
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
      it 'calls WebhookTeardownService on destroy' do
        # Mock the setup service to prevent HTTP calls during creation
        setup_service = instance_double(Whatsapp::WebhookSetupService)
        allow(Whatsapp::WebhookSetupService).to receive(:new).and_return(setup_service)
        allow(setup_service).to receive(:perform)

        channel = create(:channel_whatsapp,
                         account: account,
                         provider: 'whatsapp_cloud',
                         provider_config: {
                           'business_account_id' => 'test_waba_id',
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
