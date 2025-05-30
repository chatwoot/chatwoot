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

  describe '#toggle_typing_status' do
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:conversation) { create(:conversation) }

    it 'calls provider service method' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, toggle_typing_status: nil)
      allow(provider_double).to receive(:toggle_typing_status)
        .with(conversation.contact.phone_number, Events::Types::CONVERSATION_TYPING_ON)
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
    let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
    let(:conversation) { create(:conversation) }
    let(:message) { create(:message) }

    it 'calls provider service method' do
      provider_double = instance_double(Whatsapp::Providers::WhatsappBaileysService, read_messages: nil)
      allow(provider_double).to receive(:read_messages).with([message], conversation.contact.phone_number)
      allow(Whatsapp::Providers::WhatsappBaileysService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

      channel.read_messages([message], conversation: conversation)

      expect(provider_double).to have_received(:read_messages)
    end

    it 'does not call method if provider service does not implement it' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
      provider_double = instance_double(Whatsapp::Providers::WhatsappCloudService)
      allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new)
        .with(whatsapp_channel: channel)
        .and_return(provider_double)

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

  describe 'callbacks' do
    describe '#disconnect_channel_provider' do
      context 'when provider is baileys' do
        let(:channel) { create(:channel_whatsapp, provider: 'baileys', validate_provider_config: false, sync_templates: false) }
        let(:disconnect_url) { "#{channel.provider_config['provider_url']}/connections/#{channel.phone_number}" }

        it 'destroys the channel on successful disconnect' do
          stub_request(:delete, disconnect_url).to_return(status: 200)

          channel.destroy!

          expect(channel).to be_destroyed
        end

        it 'destroys the channel on failure to disconnect' do
          stub_request(:delete, disconnect_url).to_return(status: 404, body: 'error message')

          channel.destroy!

          expect(channel).to be_destroyed
        end
      end

      context 'when provider is not baileys' do
        let(:channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false) }

        it 'does not invoke callback' do
          expect(channel).not_to receive(:disconnect_channel_provider)

          channel.destroy!

          expect(channel).to be_destroyed
        end
      end
    end
  end
end
