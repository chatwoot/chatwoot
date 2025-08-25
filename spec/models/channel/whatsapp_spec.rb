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
    it 'generates webhook_verify_token if not present' do
      channel = create(:channel_whatsapp, provider_config: { webhook_verify_token: nil }, provider: 'whatsapp_cloud', account: create(:account),
                                          validate_provider_config: false, sync_templates: false)

      expect(channel.provider_config['webhook_verify_token']).not_to be_nil
    end

    it 'does not generate webhook_verify_token if present' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', provider_config: { webhook_verify_token: '123' }, account: create(:account),
                                          validate_provider_config: false, sync_templates: false)

      expect(channel.provider_config['webhook_verify_token']).to eq '123'
    end
  end

  describe 'provider configuration pattern' do
    let(:channel) { create(:channel_whatsapp, provider: 'whapi', account: create(:account), validate_provider_config: false, sync_templates: false) }

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
        create(:channel_whatsapp,
               provider: 'whapi',
               provider_config: { 'whapi_channel_id' => 'test_id', 'whapi_channel_token' => 'test_token', 'connection_status' => 'active' },
               account: create(:account),
               validate_provider_config: false,
               sync_templates: false)
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
        create(:channel_whatsapp,
               provider: 'whapi',
               provider_config: { 'whapi_channel_id' => 'test_id' },
               account: create(:account),
               validate_provider_config: false,
               sync_templates: false)
      end

      it 'calls cleanup through provider config object' do
        expect(Whatsapp::Whapi::WhapiChannelCleanupJob).to receive(:perform_later).with('test_id').once
        whapi_channel.destroy
      end
    end
  end
end
