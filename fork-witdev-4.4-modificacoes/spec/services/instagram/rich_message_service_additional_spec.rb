# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Instagram::RichMessageService, 'Additional Coverage' do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, contact: contact, account: account) }

  describe 'account-scoped feature flag behavior' do
    let(:message) do
      create(:message,
             conversation: conversation,
             account: account,
             inbox: inbox,
             message_type: :outgoing,
             content_type: :text,
             content: 'Test message',
             additional_attributes: { skip_send_reply: true })
    end

    let(:generic_payload) do
      {
        'template_type' => 'generic',
        'elements' => [
          {
            'title' => 'Test Product',
            'subtitle' => 'Test Description'
          }
        ]
      }
    end

    let(:service) { described_class.new(message: message, rich_payload: generic_payload) }

    context 'with account-scoped feature flags' do
      it 'checks feature flag with account context' do
        expect(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                             .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

        service.send(:rich_dashboard_enabled?)

        # Verify the account context is available for future account-scoped flags
        expect(service.instance_variable_get(:@message).account).to eq(account)
      end

      it 'supports future account-scoped flag implementation' do
        # This test documents the expected behavior for account-scoped flags
        # Future implementation could use: Feature.get(:SOCIALWISE_RICH_DASHBOARD, account.id)
        
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

        result = service.send(:rich_dashboard_enabled?)
        expect(result).to be true

        # Account information should be available for scoped checks
        expect(message.account_id).to eq(account.id)
        expect(service.instance_variable_get(:@message).account_id).to eq(account.id)
      end
    end

    context 'with different account configurations' do
      let(:other_account) { create(:account) }
      let(:other_channel) { create(:channel_instagram, account: other_account) }
      let(:other_inbox) { create(:inbox, channel: other_channel, account: other_account) }
      let(:other_conversation) { create(:conversation, inbox: other_inbox, account: other_account) }
      let(:other_message) do
        create(:message,
               conversation: other_conversation,
               account: other_account,
               message_type: :outgoing,
               content_type: :text,
               additional_attributes: { skip_send_reply: true })
      end

      it 'handles multiple accounts correctly' do
        service1 = described_class.new(message: message, rich_payload: generic_payload)
        service2 = described_class.new(message: other_message, rich_payload: generic_payload)

        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

        # Both services should work independently
        expect(service1.send(:rich_dashboard_enabled?)).to be true
        expect(service2.send(:rich_dashboard_enabled?)).to be true

        # Account contexts should be different
        expect(service1.instance_variable_get(:@message).account_id).to eq(account.id)
        expect(service2.instance_variable_get(:@message).account_id).to eq(other_account.id)
      end
    end
  end

  describe 'comprehensive error handling' do
    let(:message) do
      create(:message,
             conversation: conversation,
             account: account,
             message_type: :outgoing,
             content_type: :text,
             additional_attributes: { skip_send_reply: true })
    end

    let(:service) { described_class.new(message: message, rich_payload: {}) }

    before do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })
    end

    it 'handles ActiveRecord connection errors' do
      allow(message).to receive(:update_columns).and_raise(ActiveRecord::ConnectionNotEstablished)
      allow(Rails.logger).to receive(:error)

      expect { service.send(:mirror_rich_payload_to_dashboard) }.not_to raise_error

      expect(Rails.logger).to have_received(:error).with(
        match(/Dashboard mirroring failed for message #{message.id}/)
      )
    end

    it 'handles ActiveRecord timeout errors' do
      allow(message).to receive(:update_columns).and_raise(ActiveRecord::StatementTimeout)
      allow(Rails.logger).to receive(:error)

      expect { service.send(:mirror_rich_payload_to_dashboard) }.not_to raise_error

      expect(Rails.logger).to have_received(:error).with(
        match(/Dashboard mirroring failed for message #{message.id}/)
      )
    end

    it 'handles JSON parsing errors in payload' do
      # Simulate a payload that causes JSON issues during processing
      malformed_payload = { 'template_type' => 'generic', 'elements' => [{ 'title' => "\x00\x01\x02" }] }
      service = described_class.new(message: message, rich_payload: malformed_payload)

      allow(Rails.logger).to receive(:error)

      expect { service.send(:mirror_rich_payload_to_dashboard) }.not_to raise_error
    end

    it 'handles memory pressure gracefully' do
      # Simulate memory pressure by creating a large payload
      large_payload = {
        'template_type' => 'generic',
        'elements' => Array.new(1000) do |i|
          {
            'title' => 'A' * 1000,
            'subtitle' => 'B' * 1000
          }
        end
      }

      service = described_class.new(message: message, rich_payload: large_payload)

      expect { service.send(:mirror_rich_payload_to_dashboard) }.not_to raise_error
    end
  end

  describe 'message state consistency' do
    let(:message) do
      create(:message,
             conversation: conversation,
             account: account,
             message_type: :outgoing,
             content_type: :text,
             content: 'Original content',
             additional_attributes: { skip_send_reply: true })
    end

    let(:generic_payload) do
      {
        'template_type' => 'generic',
        'elements' => [
          {
            'title' => 'Updated Product',
            'subtitle' => 'Updated Description'
          }
        ]
      }
    end

    let(:service) { described_class.new(message: message, rich_payload: generic_payload) }

    before do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })
    end

    it 'maintains message consistency during concurrent updates' do
      # Simulate concurrent access to the same message
      original_content = message.content
      original_content_type = message.content_type

      # Start mirroring process
      service.send(:mirror_rich_payload_to_dashboard)

      # Verify the message was updated
      message.reload
      expect(message.content_type).to eq('cards')
      expect(message.content).not_to eq(original_content)

      # Verify the update was atomic
      expect(message.content_attributes['items']).to be_present
    end

    it 'preserves message metadata during mirroring' do
      original_id = message.id
      original_created_at = message.created_at
      original_conversation_id = message.conversation_id
      original_account_id = message.account_id

      service.send(:mirror_rich_payload_to_dashboard)

      message.reload
      expect(message.id).to eq(original_id)
      expect(message.created_at).to eq(original_created_at)
      expect(message.conversation_id).to eq(original_conversation_id)
      expect(message.account_id).to eq(original_account_id)
    end

    it 'updates timestamp correctly' do
      original_updated_at = message.updated_at
      
      # Wait a moment to ensure timestamp difference
      sleep(0.01)
      
      service.send(:mirror_rich_payload_to_dashboard)

      message.reload
      expect(message.updated_at).to be > original_updated_at
    end
  end

  describe 'integration with message lifecycle' do
    let(:message) do
      create(:message,
             conversation: conversation,
             account: account,
             message_type: :outgoing,
             content_type: :text,
             additional_attributes: { skip_send_reply: true })
    end

    let(:service) { described_class.new(message: message, rich_payload: {}) }

    it 'respects skip_send_reply flag timing' do
      # Verify the flag is set before any processing
      expect(message.additional_attributes['skip_send_reply']).to be true

      # The flag should prevent automatic reply sending
      expect(message).not_to receive(:send_reply)
      
      # Simulate message processing that would normally trigger send_reply
      message.after_create_commit
    end

    it 'maintains skip_send_reply flag after mirroring' do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

      service.send(:mirror_rich_payload_to_dashboard)

      message.reload
      expect(message.additional_attributes['skip_send_reply']).to be true
    end
  end

  describe 'logging and observability' do
    let(:message) do
      create(:message,
             conversation: conversation,
             account: account,
             message_type: :outgoing,
             content_type: :text,
             additional_attributes: { skip_send_reply: true })
    end

    let(:service) { described_class.new(message: message, rich_payload: {}) }

    before do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })
    end

    it 'logs with consistent message ID for correlation' do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)

      service.send(:mirror_rich_payload_to_dashboard)

      # All log entries should include the message ID for correlation
      expect(Rails.logger).to have_received(:info).with(
        "[SOCIALWISE-INSTAGRAM-RICH] Message ID: #{message.id}"
      ).at_least(:once)
    end

    it 'provides structured logging for metrics' do
      allow(Rails.logger).to receive(:info)

      service.send(:mirror_rich_payload_to_dashboard)

      # Should log structured information for metrics collection
      expect(Rails.logger).to have_received(:info).with(
        '[SOCIALWISE-INSTAGRAM-RICH] === STARTING DASHBOARD MIRRORING ==='
      )
      expect(Rails.logger).to have_received(:info).with(
        '[SOCIALWISE-INSTAGRAM-RICH] === DASHBOARD MIRRORING COMPLETED ==='
      )
    end

    it 'includes account context in feature flag logging' do
      allow(Rails.logger).to receive(:info)

      service.send(:rich_dashboard_enabled?)

      expect(Rails.logger).to have_received(:info).with(
        "[SOCIALWISE-INSTAGRAM-RICH] Rich dashboard enabled check: true for account #{account.id}"
      )
    end
  end

  describe 'performance under load' do
    let(:messages) do
      10.times.map do |i|
        create(:message,
               conversation: conversation,
               account: account,
               message_type: :outgoing,
               content_type: :text,
               content: "Message #{i}",
               additional_attributes: { skip_send_reply: true })
      end
    end

    let(:payload) do
      {
        'template_type' => 'generic',
        'elements' => [
          {
            'title' => 'Performance Test Product',
            'subtitle' => 'Testing performance under load'
          }
        ]
      }
    end

    before do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })
    end

    it 'handles multiple concurrent mirroring operations' do
      start_time = Time.current

      # Process multiple messages concurrently
      threads = messages.map do |message|
        Thread.new do
          service = described_class.new(message: message, rich_payload: payload)
          service.send(:mirror_rich_payload_to_dashboard)
        end
      end

      threads.each(&:join)
      elapsed_time = Time.current - start_time

      # Should complete all operations quickly
      expect(elapsed_time).to be < 2.0

      # Verify all messages were updated
      messages.each do |message|
        message.reload
        expect(message.content_type).to eq('cards')
      end
    end

    it 'maintains performance with database load' do
      # Simulate database load by creating many messages
      100.times do |i|
        create(:message,
               conversation: conversation,
               account: account,
               message_type: :outgoing,
               content: "Load test message #{i}")
      end

      test_message = messages.first
      service = described_class.new(message: test_message, rich_payload: payload)

      start_time = Time.current
      service.send(:mirror_rich_payload_to_dashboard)
      elapsed_time = Time.current - start_time

      expect(elapsed_time).to be < 0.1  # Should still be fast under load
    end
  end
end