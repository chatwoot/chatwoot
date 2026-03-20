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

        channel.destroy!

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

        channel.destroy!

        expect(teardown_service).to have_received(:perform)
      end
    end
  end

  describe '#toggle_typing_status' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:conversation) { create(:conversation) }

    it 'calls provider service method' do
      message = create(:message, conversation: conversation)
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, toggle_typing_status: nil)
      allow(provider_double).to receive(:toggle_typing_status)
        .with(Events::Types::CONVERSATION_TYPING_ON, recipient_id: conversation.contact.identifier, last_message: message)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.toggle_typing_status(Events::Types::CONVERSATION_TYPING_ON, conversation: conversation)

      expect(provider_double).to have_received(:toggle_typing_status)
    end

    it 'does not call method if provider service does not implement it' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
      provider_double = instance_double(Whatsapp::Providers::WhatsappCloudService)
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      expect do
        channel.toggle_typing_status(Events::Types::CONVERSATION_TYPING_ON, conversation: conversation)
      end.not_to raise_error
    end
  end

  describe '#update_presence' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }

    it 'calls provider service method' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, update_presence: nil)
      allow(provider_double).to receive(:update_presence).with('online')
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.update_presence('online')

      expect(provider_double).to have_received(:update_presence)
    end

    it 'does not call method if provider service does not implement it' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
      provider_double = instance_double(Whatsapp::Providers::WhatsappCloudService)
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      expect do
        channel.update_presence('online')
      end.not_to raise_error
    end
  end

  describe '#read_messages' do
    let(:channel) do
      create(:channel_whatsapp, provider: 'baileys', provider_config: { mark_as_read: true }, validate_provider_config: false, sync_templates: false)
    end
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message, conversation: conversation) }

    it 'calls provider service method' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, read_messages: nil)
      allow(provider_double).to receive(:read_messages).with([message], recipient_id: conversation.contact.identifier)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.read_messages([message], conversation: conversation)

      expect(provider_double).to have_received(:read_messages)
    end

    it 'call method when the provider config mark_as_read is nil' do
      channel.update!(provider_config: {})
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, read_messages: nil)
      allow(provider_double).to receive(:read_messages).with([message], recipient_id: conversation.contact.identifier)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.read_messages([message], conversation: conversation)

      expect(provider_double).to have_received(:read_messages)
    end

    it 'does not call method if provider service does not implement it' do
      channel.update!(provider: 'default')

      expect do
        channel.read_messages([message], conversation: conversation)
      end.not_to raise_error
    end

    it 'does not call method if provider config mark_as_read is false' do
      channel.update!(provider_config: { mark_as_read: false })

      expect do
        channel.read_messages([message], conversation: conversation)
      end.not_to raise_error
    end
  end

  describe '#unread_conversation' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:conversation) { create(:conversation) }

    it 'calls provider service method' do
      message = create(:message, conversation: conversation, message_type: 'incoming')
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, unread_message: nil)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).with(whatsapp_channel: channel).and_return(provider_double)
      allow(provider_double).to receive(:unread_message).with(conversation.contact.phone_number, [message])

      channel.unread_conversation(conversation)

      expect(provider_double).to have_received(:unread_message)
    end

    it 'does not call method if provider service does not implement it' do
      # NOTE: This message ensures that there are messages but the provider does not implement the method.
      create(:message, conversation: conversation, message_type: 'incoming')

      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).with(whatsapp_channel: channel).and_return(provider_double)

      expect do
        channel.unread_conversation(conversation)
      end
        .not_to raise_error
    end

    it 'does not call method if there are no messages' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, unread_message: nil)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new).with(whatsapp_channel: channel).and_return(provider_double)
      allow(provider_double).to receive(:unread_message)

      channel.unread_conversation(conversation)

      expect(provider_double).not_to have_received(:unread_message)
    end
  end

  describe '#received_messages' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:conversation) { create(:conversation) }
    let(:messages) { [create(:message, conversation: conversation)] }

    it 'calls provider service method' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, received_messages: nil)
      allow(provider_double).to receive(:received_messages).with(conversation.contact.identifier, messages)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.received_messages(messages, conversation)

      expect(provider_double).to have_received(:received_messages)
    end

    it 'does not call method if provider service does not implement it' do
      channel.update!(provider: 'whatsapp_cloud')

      expect do
        channel.received_messages(messages, conversation)
      end.not_to raise_error
    end
  end

  describe '#on_whatsapp' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:conversation) { create(:conversation) }
    let(:phone_number) { '+123456789' }

    it 'calls provider service method' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, on_whatsapp: nil)
      allow(provider_double).to receive(:on_whatsapp).with(phone_number)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.on_whatsapp(phone_number)

      expect(provider_double).to have_received(:on_whatsapp)
    end

    it 'does not call method if provider service does not implement it' do
      channel.update!(provider: 'whatsapp_cloud')

      expect do
        channel.on_whatsapp(phone_number)
      end.not_to raise_error
    end
  end

  describe '#delete_message' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:contact) { create(:contact, identifier: '+551187654321') }
    let(:contact_inbox) { create(:contact_inbox, inbox: channel.inbox, contact: contact) }
    let(:conversation) { create(:conversation, inbox: channel.inbox, contact: contact, contact_inbox: contact_inbox) }
    let(:message) { create(:message, conversation: conversation, inbox: channel.inbox, source_id: 'msg_123', message_type: :outgoing) }

    it 'calls provider service delete_message method for baileys' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, delete_message: true)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.delete_message(message, conversation: conversation)

      expect(provider_double).to have_received(:delete_message).with(contact.identifier, message)
    end

    it 'calls provider service delete_message method for zapi with phone_number' do
      contact.update!(phone_number: '+551199999999')
      channel.update!(provider: 'zapi')
      provider_double = instance_double(Whatsapp::Providers::WhatsappZapiService, delete_message: true)
      allow(Whatsapp::Providers::WhatsappZapiService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.delete_message(message, conversation: conversation)

      expect(provider_double).to have_received(:delete_message).with(contact.phone_number, message)
    end

    it 'calls provider service delete_message method for zapi falling back to identifier when phone_number is blank' do
      channel.update!(provider: 'zapi')
      provider_double = instance_double(Whatsapp::Providers::WhatsappZapiService, delete_message: true)
      allow(Whatsapp::Providers::WhatsappZapiService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.delete_message(message, conversation: conversation)

      expect(provider_double).to have_received(:delete_message).with(contact.identifier, message)
    end

    it 'does not call method if provider service does not implement it' do
      channel.update!(provider: 'whatsapp_cloud')

      expect do
        channel.delete_message(message, conversation: conversation)
      end.not_to raise_error
    end
  end

  describe 'callbacks' do
    describe '#disconnect_channel_provider' do
      context 'when provider implements the method' do
        let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
        let(:disconnect_url) { "#{channel.provider_config['provider_url']}/connections/#{channel.phone_number}" }

        it 'destroys the channel on successful disconnect' do
          stub_request(:delete, disconnect_url).to_return(status: 200)

          channel.destroy!

          expect(channel).to be_destroyed
        end

        it 'destroys the channel on failure to disconnect' do
          stub_request(:delete, disconnect_url).to_return(status: 404, body: 'error message')
          # NOTE: On failure, `setup_channel_provider` is called, so we re-stub to avoid errors
          stub_request(:post, disconnect_url).to_return(status: 200)

          channel.destroy!

          expect(channel).to be_destroyed
        end
      end

      context 'when provider does not implement the method' do
        let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }

        before do
          stub_request(:delete, "https://graph.facebook.com/v22.0/#{channel.provider_config['business_account_id']}/subscribed_apps")
            .to_return(status: 200, body: '', headers: {})
        end

        it 'does not invoke callback' do
          expect(channel).not_to receive(:disconnect_channel_provider)

          channel.destroy!

          expect(channel).to be_destroyed
        end
      end
    end
  end

  describe '#provider_connection_data' do
    let(:channel) do
      create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false,
                                provider_connection: {
                                  'connection' => 'open',
                                  'qr_data_url' => 'data:image/png;base64,test',
                                  'error' => 'some_error'
                                })
    end

    context 'when user is an administrator' do
      it 'includes qr_data_url and error in the response' do
        account_user = create(:account_user, account: channel.account, role: :administrator)
        allow(Current).to receive(:account_user).and_return(account_user)

        data = channel.provider_connection_data

        expect(data).to eq({
                             connection: 'open',
                             qr_data_url: 'data:image/png;base64,test',
                             error: 'some_error'
                           })
      end
    end

    context 'when user is not an administrator' do
      it 'excludes qr_data_url and error from the response' do
        account_user = create(:account_user, account: channel.account, role: :agent)
        allow(Current).to receive(:account_user).and_return(account_user)

        data = channel.provider_connection_data

        expect(data).to eq({ connection: 'open' })
      end
    end

    context 'when Current.account_user is nil' do
      it 'excludes qr_data_url and error from the response' do
        allow(Current).to receive(:account_user).and_return(nil)

        data = channel.provider_connection_data

        expect(data).to eq({ connection: 'open' })
      end
    end
  end

  describe '#sync_group' do
    it 'delegates to provider_service when it supports sync_group' do
      channel = create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false)
      conversation = create(:conversation, inbox: channel.inbox, account: channel.account)
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, sync_group: nil)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.sync_group(conversation)

      expect(provider_double).to have_received(:sync_group).with(conversation, soft: false)
    end

    it 'does nothing when provider_service does not support sync_group' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
      conversation = create(:conversation, inbox: channel.inbox, account: channel.account)
      provider_double = instance_double(Whatsapp::Providers::WhatsappCloudService)
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      expect(channel.sync_group(conversation)).to be_nil
    end
  end
end
