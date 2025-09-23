# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ForwardNotificationService do
  subject(:service) { described_class.new(message) }

  let!(:account) { create(:account, custom_attributes: { 'store_id' => 'test_store_123' }) }
  let!(:conversation) { create(:conversation, account: account) }
  let!(:message) do
    create(:message, conversation: conversation, account: account, content: '[test]: Test notification', message_type: 'outgoing', private: true)
  end

  let(:whatsapp_channel) { instance_double(Channel::Whatsapp) }
  let(:config_service_double) { instance_double(AiBackendService::ConfigurationService) }
  let(:notification_config) do
    {
      'channels' => [
        {
          'channel' => 'whatsapp',
          'target_chats' => %w[1234567890 0987654321]
        }
      ]
    }
  end

  before do
    allow(AiBackendService::ConfigurationService).to receive(:new).and_return(config_service_double)
    allow(config_service_double).to receive(:get_configuration).and_return(notification_config)
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:warn)
  end

  describe '#initialize' do
    it 'sets instance variables correctly' do
      expect(service.instance_variable_get(:@message)).to eq(message)
      expect(service.instance_variable_get(:@conversation)).to eq(conversation)
      expect(service.instance_variable_get(:@account)).to eq(account)
    end
  end

  describe '#send_notification' do
    it 'enqueues ForwardNotificationJob' do
      expect(ForwardNotificationJob).to receive(:perform_later).with(message.id)

      service.send_notification
    end

    context 'when an error occurs' do
      before do
        allow(ForwardNotificationJob).to receive(:perform_later).and_raise(StandardError, 'Test error')
      end

      it 'logs the error and does not re-raise' do
        expect { service.send_notification }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with('Error enqueuing notification job: Test error')
      end
    end
  end

  describe '#perform_notification_sending' do
    context 'when notification channels are configured' do
      it 'processes notification channels successfully' do
        allow(service).to receive(:send_to_channel)

        service.perform_notification_sending

        expect(service).to have_received(:send_to_channel).once
      end
    end

    context 'when no notification channels are configured' do
      before do
        allow(config_service_double).to receive(:get_configuration).and_return(nil)
      end

      it 'returns early without processing' do
        allow(service).to receive(:send_to_channel)

        service.perform_notification_sending

        expect(service).not_to have_received(:send_to_channel)
      end
    end

    context 'when an error occurs' do
      before do
        allow(service).to receive(:extract_notification_channels).and_raise(StandardError, 'Test error')
      end

      it 'logs the error and does not re-raise' do
        expect { service.perform_notification_sending }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with('Error in ForwardNotificationService.perform_notification_sending: Test error')
      end
    end
  end

  describe '#extract_notification_channels' do
    it 'extracts channels correctly from configuration' do
      result = service.send(:extract_notification_channels)

      expect(result).to eq([
                             {
                               channel: 'whatsapp',
                               target_chats: %w[1234567890 0987654321]
                             }
                           ])
    end

    context 'when configuration has no channels' do
      before do
        allow(config_service_double).to receive(:get_configuration).and_return({ 'other_data' => 'value' })
      end

      it 'returns empty array' do
        result = service.send(:extract_notification_channels)
        expect(result).to eq([])
      end
    end

    context 'when configuration is nil' do
      before do
        allow(config_service_double).to receive(:get_configuration).and_return(nil)
      end

      it 'returns empty array' do
        result = service.send(:extract_notification_channels)
        expect(result).to eq([])
      end
    end
  end

  describe '#send_to_channel' do
    let(:channel_config) do
      {
        channel: 'whatsapp',
        target_chats: ['1234567890']
      }
    end

    context 'when channel is whatsapp' do
      it 'calls send_whatsapp_notifications' do
        allow(service).to receive(:send_whatsapp_notifications)

        service.send(:send_to_channel, channel_config)

        expect(service).to have_received(:send_whatsapp_notifications).with(['1234567890'])
      end
    end

    context 'when channel is unknown' do
      let(:unknown_channel_config) do
        {
          channel: 'unknown_channel',
          target_chats: ['1234567890']
        }
      end

      it 'logs a warning' do
        service.send(:send_to_channel, unknown_channel_config)

        expect(Rails.logger).to have_received(:warn).with('Not implemented notification channel: unknown_channel')
      end
    end
  end

  describe 'WhatsApp notifications with environment variable' do
    context 'when DEFAULT_WHAPI_CHANNEL_TOKEN environment variable is set' do
      let(:mock_whapi_channel) { instance_double(Channel::Whatsapp) }

      before do
        allow(ENV).to receive(:fetch).with('DEFAULT_WHAPI_CHANNEL_TOKEN', nil).and_return('test_api_key_123')
        allow(service).to receive(:create_whapi_channel).and_return(mock_whapi_channel)
        allow(mock_whapi_channel).to receive(:provider_config).and_return({ 'api_key' => 'test_api_key_123' })
        allow(service).to receive(:send_via_whatsapp_channel)
      end

      it 'creates a WHAPI channel with the environment variable and sends notifications' do
        service.perform_notification_sending

        expect(service).to have_received(:create_whapi_channel)
        expect(service).to have_received(:send_via_whatsapp_channel).with(mock_whapi_channel, '1234567890', '[test]: Test notification')
        expect(service).to have_received(:send_via_whatsapp_channel).with(mock_whapi_channel, '0987654321', '[test]: Test notification')
      end
    end

    context 'when DEFAULT_WHAPI_CHANNEL_TOKEN environment variable is not set' do
      before do
        allow(ENV).to receive(:fetch).with('DEFAULT_WHAPI_CHANNEL_TOKEN', nil).and_return(nil)
      end

      it 'logs an error and returns early' do
        allow(service).to receive(:send_via_whatsapp_channel)

        service.perform_notification_sending

        expect(Rails.logger).to have_received(:error).with("Account #{account.id} with no whapi channel and no default whapi channel token defined")
        expect(service).not_to have_received(:send_via_whatsapp_channel)
      end
    end

    context 'when DEFAULT_WHAPI_CHANNEL_TOKEN environment variable is empty' do
      before do
        allow(ENV).to receive(:fetch).with('DEFAULT_WHAPI_CHANNEL_TOKEN', nil).and_return('')
      end

      it 'logs an error and returns early' do
        allow(service).to receive(:send_via_whatsapp_channel)

        service.perform_notification_sending

        expect(Rails.logger).to have_received(:error).with("Account #{account.id} with no whapi channel and no default whapi channel token defined")
        expect(service).not_to have_received(:send_via_whatsapp_channel)
      end
    end
  end

  describe '#send_via_whatsapp_channel' do
    let(:target_chat) { '1234567890' }
    let(:notification_message) { '[alert]: Important notification' }
    let(:mock_whapi_service) { instance_double(Whatsapp::Providers::WhapiService) }

    context 'when message is sent successfully' do
      before do
        allow(Whatsapp::Providers::WhapiService).to receive(:new).and_return(mock_whapi_service)
        allow(mock_whapi_service).to receive(:send_message).and_return('msg_12345')
      end

      it 'creates a proper message object and sends via WhatsApp channel' do
        service.send(:send_via_whatsapp_channel, whatsapp_channel, target_chat, notification_message)

        expect(Whatsapp::Providers::WhapiService).to have_received(:new).with(whatsapp_channel: whatsapp_channel)
        expect(mock_whapi_service).to have_received(:send_message) do |chat_id, message_obj|
          expect(chat_id).to eq(target_chat)
          expect(message_obj.content).to eq(notification_message)
          expect(message_obj.content_type).to eq('text')
          expect(message_obj.message_type).to eq('outgoing')
          expect(message_obj.private).to be false
          expect(message_obj.attachments).to eq([])
          expect(message_obj.content_attributes).to eq({})
        end
      end

      it 'creates message object with proper outgoing_content method' do
        service.send(:send_via_whatsapp_channel, whatsapp_channel, target_chat, notification_message)

        expect(mock_whapi_service).to have_received(:send_message) do |_chat_id, message_obj|
          expect(message_obj.outgoing_content).to eq(notification_message)
        end
      end
    end

    context 'when an error occurs during sending' do
      before do
        allow(Whatsapp::Providers::WhapiService).to receive(:new).and_return(mock_whapi_service)
        allow(mock_whapi_service).to receive(:send_message).and_raise(StandardError, 'Network error')
      end

      it 'logs the error and does not re-raise' do
        expect { service.send(:send_via_whatsapp_channel, whatsapp_channel, target_chat, notification_message) }.not_to raise_error

        expect(Rails.logger).to have_received(:error).with("Failed to send WhatsApp notification to #{target_chat}: Network error")
      end
    end
  end

  describe '#create_whapi_channel' do
    let(:api_key) { 'test_api_key_123' }

    it 'creates a Channel::Whatsapp instance with the provided API key' do
      result = service.send(:create_whapi_channel, api_key)

      expect(result).to be_a(Channel::Whatsapp)
      expect(result.provider).to eq('whapi')
      expect(result.provider_config['api_key']).to eq(api_key)
      expect(result.account).to eq(account)
    end
  end

  describe '#find_notification_config' do
    context 'when store_id is present and configuration service returns data' do
      it 'returns the configuration from the service' do
        result = service.send(:find_notification_config)

        expect(config_service_double).to have_received(:get_configuration).with(
          'test_store_123',
          AiBackendService::ConfigurationService::CONFIGURATION_KEYS[:NOTIFICATIONS]
        )
        expect(result).to eq(notification_config)
      end
    end

    context 'when store_id is not present' do
      before do
        account.update!(custom_attributes: {})
      end

      it 'returns nil without calling the configuration service' do
        result = service.send(:find_notification_config)

        expect(config_service_double).not_to have_received(:get_configuration)
        expect(result).to be_nil
      end
    end

    context 'when configuration service returns nil' do
      before do
        allow(config_service_double).to receive(:get_configuration).and_return(nil)
      end

      it 'returns nil' do
        result = service.send(:find_notification_config)

        expect(result).to be_nil
      end
    end

    context 'when configuration service raises an error' do
      before do
        allow(config_service_double).to receive(:get_configuration).and_raise(StandardError, 'Config service error')
      end

      it 'logs the error and returns nil' do
        result = service.send(:find_notification_config)

        expect(Rails.logger).to have_received(:error).with('Error getting notification config: Config service error')
        expect(result).to be_nil
      end
    end
  end
end