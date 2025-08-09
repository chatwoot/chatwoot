# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ForwardNotificationService do
  # Test setup and dependencies
  let!(:account) { create(:account, custom_attributes: { 'store_id' => 'test_store_123' }) }
  let!(:conversation) { create(:conversation, account: account) }
  let!(:message) do
    create(:message, conversation: conversation, account: account, content: '[test]: Test notification', message_type: 'outgoing', private: true)
  end

  # Mock the WhatsApp channel instead of creating a real one
  let(:whatsapp_channel) { instance_double(Channel::Whatsapp) }
  # New: scope/association proxy that responds to find_by
  let(:whatsapp_channel_scope) { instance_double('WhatsappChannelScope') }
  let(:service) { described_class.new(message) }

  # Mock external dependencies
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

  # Test Isolation
  before do
    # Mock the configuration service
    allow(AiBackendService::ConfigurationService).to receive(:new).and_return(config_service_double)
    allow(config_service_double).to receive(:get_configuration).and_return(notification_config)

    # Mock the account's whatsapp_channels association to return a scope-like object
    allow(account).to receive(:whatsapp_channels).and_return(whatsapp_channel_scope)
    allow(whatsapp_channel_scope).to receive(:find_by).with(provider: 'whapi').and_return(whatsapp_channel)
  end

  describe '#initialize' do
    it 'sets instance variables correctly' do
      expect(service.instance_variable_get(:@message)).to eq(message)
      expect(service.instance_variable_get(:@conversation)).to eq(conversation)
      expect(service.instance_variable_get(:@account)).to eq(account)
    end
  end

  describe '#send_notification' do
    context 'when notification channels are configured' do
      it 'processes notification channels successfully' do
        allow(service).to receive(:send_to_channel)

        service.send_notification

        expect(service).to have_received(:send_to_channel).once
      end
    end

    context 'when no notification channels are configured' do
      before do
        allow(config_service_double).to receive(:get_configuration).and_return(nil)
      end

      it 'returns early without processing' do
        allow(service).to receive(:send_to_channel)

        service.send_notification

        expect(service).not_to have_received(:send_to_channel)
      end
    end

    context 'when an error occurs' do
      before do
        allow(service).to receive(:extract_notification_channels).and_raise(StandardError, 'Test error')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error and does not re-raise' do
        expect { service.send_notification }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with('Error in ForwardNotificationService.send_notification: Test error')
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

      before do
        allow(Rails.logger).to receive(:warn)
      end

      it 'logs a warning' do
        service.send(:send_to_channel, unknown_channel_config)

        expect(Rails.logger).to have_received(:warn).with('Unknown notification channel: unknown_channel')
      end
    end
  end

  describe '#send_whatsapp_notifications' do
    let(:target_chats) { %w[1234567890 0987654321] }

    context 'when WhatsApp channel exists' do
      it 'sends notifications to all target chats' do
        allow(service).to receive(:send_via_whatsapp_channel)

        service.send(:send_whatsapp_notifications, target_chats)

        expect(service).to have_received(:send_via_whatsapp_channel).with(whatsapp_channel, '1234567890', '[test]: Test notification')
        expect(service).to have_received(:send_via_whatsapp_channel).with(whatsapp_channel, '0987654321', '[test]: Test notification')
      end
    end

    context 'when no WhatsApp channel exists' do
      before do
        # Return nil when finding by provider
        allow(whatsapp_channel_scope).to receive(:find_by).with(provider: 'whapi').and_return(nil)
        allow(Rails.logger).to receive(:warn)
      end

      it 'logs a warning and returns early' do
        allow(service).to receive(:send_via_whatsapp_channel)

        service.send(:send_whatsapp_notifications, target_chats)

        expect(Rails.logger).to have_received(:warn).with("No WhatsApp channels with provider 'whapi' found for account #{account.id}")
        expect(service).not_to have_received(:send_via_whatsapp_channel)
      end
    end
  end

  describe '#send_via_whatsapp_channel' do
    let(:target_chat) { '1234567890' }
    let(:notification_message) { '[alert]: Important notification' }
    let(:mock_message_id) { 'msg_12345' }

    context 'when message is sent successfully' do
      before do
        allow(whatsapp_channel).to receive(:send_message).and_return(mock_message_id)
        allow(Rails.logger).to receive(:info)
      end

      it 'creates a proper message object and sends via WhatsApp channel' do
        service.send(:send_via_whatsapp_channel, whatsapp_channel, target_chat, notification_message)

        expect(whatsapp_channel).to have_received(:send_message) do |chat_id, message_obj|
          expect(chat_id).to eq(target_chat)
          expect(message_obj.content).to eq(notification_message)
          expect(message_obj.content_type).to eq('text')
          expect(message_obj.message_type).to eq('outgoing')
          expect(message_obj.private).to be false
          expect(message_obj.attachments).to eq([])
          expect(message_obj.content_attributes).to eq({})
        end

        expect(Rails.logger).to have_received(:info).with("WhatsApp notification sent successfully to #{target_chat}. Message ID: #{mock_message_id}")
      end

      it 'creates message object with proper outgoing_content method' do
        service.send(:send_via_whatsapp_channel, whatsapp_channel, target_chat, notification_message)

        expect(whatsapp_channel).to have_received(:send_message) do |_chat_id, message_obj|
          expect(message_obj.outgoing_content).to eq(notification_message)
        end
      end
    end

    context 'when an error occurs during sending' do
      before do
        allow(whatsapp_channel).to receive(:send_message).and_raise(StandardError, 'Network error')
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error and does not re-raise' do
        expect { service.send(:send_via_whatsapp_channel, whatsapp_channel, target_chat, notification_message) }.not_to raise_error

        expect(Rails.logger).to have_received(:error).with("Failed to send WhatsApp notification to #{target_chat}: Network error")
      end
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
        allow(Rails.logger).to receive(:error)
      end

      it 'logs the error and returns nil' do
        result = service.send(:find_notification_config)

        expect(Rails.logger).to have_received(:error).with('Error getting notification config: Config service error')
        expect(result).to be_nil
      end
    end
  end
end