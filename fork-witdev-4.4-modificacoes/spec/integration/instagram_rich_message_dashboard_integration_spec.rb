# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Instagram Rich Message Dashboard Integration' do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, inbox: inbox, contact: contact, account: account) }

  let(:generic_payload) do
    {
      'template_type' => 'generic',
      'elements' => [
        {
          'title' => 'Integration Test Product',
          'subtitle' => 'Testing end-to-end flow',
          'image_url' => 'https://example.com/test-image.jpg',
          'buttons' => [
            {
              'type' => 'web_url',
              'title' => 'View Product',
              'url' => 'https://example.com/product'
            },
            {
              'type' => 'postback',
              'title' => 'Buy Now',
              'payload' => 'BUY_INTEGRATION_TEST'
            }
          ]
        }
      ]
    }
  end

  let(:button_payload) do
    {
      'template_type' => 'button',
      'text' => 'Integration test: Choose an option',
      'buttons' => [
        {
          'type' => 'postback',
          'title' => 'Yes',
          'payload' => 'INTEGRATION_YES'
        },
        {
          'type' => 'postback',
          'title' => 'No',
          'payload' => 'INTEGRATION_NO'
        }
      ]
    }
  end

  let(:quick_replies_payload) do
    {
      'text' => 'Integration test: What would you like to do?',
      'quick_replies' => [
        {
          'content_type' => 'text',
          'title' => 'Test Option 1',
          'payload' => 'INTEGRATION_OPTION_1'
        },
        {
          'content_type' => 'text',
          'title' => 'Test Option 2',
          'payload' => 'INTEGRATION_OPTION_2'
        }
      ]
    }
  end

  before do
    # Mock Instagram API calls
    stub_request(:post, /graph\.instagram\.com/)
      .to_return(status: 200, body: { message_id: 'integration_test_message_id' }.to_json)

    # Mock GlobalConfig for human agent tag
    allow(GlobalConfig).to receive(:get).with('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')
                                        .and_return({ 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT' => false })
  end

  describe 'complete rich message flow with dashboard mirroring' do
    context 'when SOCIALWISE_RICH_DASHBOARD feature flag is enabled' do
      before do
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })
      end

      it 'processes Generic Template end-to-end' do
        # Create message with skip_send_reply flag
        message = conversation.messages.create!(
          content: 'Fallback text for generic template',
          message_type: :outgoing,
          account_id: account.id,
          inbox_id: inbox.id,
          additional_attributes: { skip_send_reply: true }
        )

        # Process through Instagram Rich Message Service
        service = Instagram::RichMessageService.new(message: message, rich_payload: generic_payload)
        service.perform

        # Verify message was updated with rich content
        message.reload
        expect(message.content_type).to eq('cards')
        expect(message.content_attributes['items']).to be_present
        expect(message.content_attributes['items'].length).to eq(1)

        # Verify card content
        card = message.content_attributes['items'].first
        expect(card['title']).to eq('Integration Test Product')
        expect(card['description']).to eq('Testing end-to-end flow')
        expect(card['media_url']).to eq('https://example.com/test-image.jpg')
        expect(card['actions']).to be_present
        expect(card['actions'].length).to eq(2)

        # Verify actions
        link_action = card['actions'].find { |a| a['type'] == 'link' }
        expect(link_action['text']).to eq('View Product')
        expect(link_action['uri']).to eq('https://example.com/product')

        postback_action = card['actions'].find { |a| a['type'] == 'postback' }
        expect(postback_action['text']).to eq('Buy Now')
        expect(postback_action['payload']).to eq('BUY_INTEGRATION_TEST')

        # Verify fallback text
        expect(message.content).to eq('Integration Test Product — Testing end-to-end flow')

        # Verify Instagram API was called
        expect(WebMock).to have_requested(:post, /graph\.instagram\.com/)
      end

      it 'processes Button Template end-to-end' do
        message = conversation.messages.create!(
          content: 'Fallback text for button template',
          message_type: :outgoing,
          account_id: account.id,
          inbox_id: inbox.id,
          additional_attributes: { skip_send_reply: true }
        )

        service = Instagram::RichMessageService.new(message: message, rich_payload: button_payload)
        service.perform

        message.reload
        expect(message.content_type).to eq('cards')
        expect(message.content_attributes['items'].length).to eq(1)

        card = message.content_attributes['items'].first
        expect(card['body']).to eq('Integration test: Choose an option')
        expect(card['actions'].length).to eq(2)

        expect(message.content).to eq('Integration test: Choose an option')
        expect(WebMock).to have_requested(:post, /graph\.instagram\.com/)
      end

      it 'processes Quick Replies end-to-end' do
        message = conversation.messages.create!(
          content: 'Fallback text for quick replies',
          message_type: :outgoing,
          account_id: account.id,
          inbox_id: inbox.id,
          additional_attributes: { skip_send_reply: true }
        )

        service = Instagram::RichMessageService.new(message: message, rich_payload: quick_replies_payload)
        service.perform

        message.reload
        expect(message.content_type).to eq('input_select')
        expect(message.content_attributes['items'].length).to eq(2)

        items = message.content_attributes['items']
        expect(items.first['title']).to eq('Test Option 1')
        expect(items.first['value']).to eq('INTEGRATION_OPTION_1')
        expect(items.last['title']).to eq('Test Option 2')
        expect(items.last['value']).to eq('INTEGRATION_OPTION_2')

        expect(message.content).to eq('Integration test: What would you like to do? (2 options)')
        expect(WebMock).to have_requested(:post, /graph\.instagram\.com/)
      end

      it 'maintains message serialization compatibility' do
        message = conversation.messages.create!(
          content: 'Test message',
          message_type: :outgoing,
          account_id: account.id,
          inbox_id: inbox.id,
          additional_attributes: { skip_send_reply: true }
        )

        service = Instagram::RichMessageService.new(message: message, rich_payload: generic_payload)
        service.perform

        message.reload

        # Verify database storage (integer)
        expect(message.read_attribute_before_type_cast('content_type')).to eq(Message.content_types['cards'])
        expect(message.read_attribute_before_type_cast('content_type')).to be_a(Integer)

        # Verify enum method (string)
        expect(message.content_type).to eq('cards')
        expect(message.content_type).to be_a(String)

        # Verify JSON serialization would work
        expect(message.content_attributes).to be_a(Hash)
        expect(message.content_attributes['items']).to be_an(Array)
      end

      it 'handles errors gracefully without affecting Instagram API calls' do
        message = conversation.messages.create!(
          content: 'Test message',
          message_type: :outgoing,
          account_id: account.id,
          inbox_id: inbox.id,
          additional_attributes: { skip_send_reply: true }
        )

        # Mock mapper to fail
        allow(Messages::InstagramRendererMapper).to receive(:map).and_raise(StandardError, 'Test error')
        allow(Rails.logger).to receive(:error)

        service = Instagram::RichMessageService.new(message: message, rich_payload: generic_payload)

        # Should not raise error
        expect { service.perform }.not_to raise_error

        # Should still call Instagram API
        expect(WebMock).to have_requested(:post, /graph\.instagram\.com/)

        # Should log error
        expect(Rails.logger).to have_received(:error).with(
          match(/Dashboard mirroring failed for message #{message.id}/)
        )

        # Message should remain unchanged
        message.reload
        expect(message.content_type).to eq('text')
        expect(message.content).to eq('Test message')
      end
    end

    context 'when SOCIALWISE_RICH_DASHBOARD feature flag is disabled' do
      before do
        allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                            .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => nil })
      end

      it 'skips dashboard mirroring but continues with Instagram API' do
        message = conversation.messages.create!(
          content: 'Original text content',
          message_type: :outgoing,
          account_id: account.id,
          inbox_id: inbox.id,
          additional_attributes: { skip_send_reply: true }
        )

        service = Instagram::RichMessageService.new(message: message, rich_payload: generic_payload)
        service.perform

        # Message should remain unchanged
        message.reload
        expect(message.content_type).to eq('text')
        expect(message.content).to eq('Original text content')
        expect(message.content_attributes).to be_blank

        # Instagram API should still be called
        expect(WebMock).to have_requested(:post, /graph\.instagram\.com/)
      end
    end
  end

  describe 'performance and reliability' do
    before do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })
    end

    it 'completes the entire flow within reasonable time' do
      message = conversation.messages.create!(
        content: 'Performance test message',
        message_type: :outgoing,
        account_id: account.id,
        inbox_id: inbox.id,
        additional_attributes: { skip_send_reply: true }
      )

      service = Instagram::RichMessageService.new(message: message, rich_payload: generic_payload)

      start_time = Time.current
      service.perform
      elapsed_time = Time.current - start_time

      # Should complete in under 1 second
      expect(elapsed_time).to be < 1.0
    end

    it 'handles concurrent message processing' do
      messages = 3.times.map do |i|
        conversation.messages.create!(
          content: "Concurrent test message #{i}",
          message_type: :outgoing,
          account_id: account.id,
          inbox_id: inbox.id,
          additional_attributes: { skip_send_reply: true }
        )
      end

      # Process messages concurrently
      threads = messages.map do |message|
        Thread.new do
          service = Instagram::RichMessageService.new(message: message, rich_payload: generic_payload)
          service.perform
        end
      end

      threads.each(&:join)

      # Verify all messages were processed correctly
      messages.each do |message|
        message.reload
        expect(message.content_type).to eq('cards')
        expect(message.content_attributes['items']).to be_present
      end

      # Verify all Instagram API calls were made
      expect(WebMock).to have_requested(:post, /graph\.instagram\.com/).times(3)
    end
  end

  describe 'backward compatibility' do
    it 'does not affect existing message processing when feature is disabled' do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => nil })

      # Create a regular message (not through rich message service)
      regular_message = conversation.messages.create!(
        content: 'Regular text message',
        message_type: :outgoing,
        account_id: account.id,
        inbox_id: inbox.id
      )

      # Verify it remains unchanged
      expect(regular_message.content_type).to eq('text')
      expect(regular_message.content).to eq('Regular text message')
      expect(regular_message.content_attributes).to be_blank

      # Process a rich message with feature disabled
      rich_message = conversation.messages.create!(
        content: 'Rich message with feature disabled',
        message_type: :outgoing,
        account_id: account.id,
        inbox_id: inbox.id,
        additional_attributes: { skip_send_reply: true }
      )

      service = Instagram::RichMessageService.new(message: rich_message, rich_payload: generic_payload)
      service.perform

      # Rich message should not be modified
      rich_message.reload
      expect(rich_message.content_type).to eq('text')
      expect(rich_message.content).to eq('Rich message with feature disabled')

      # But Instagram API should still work
      expect(WebMock).to have_requested(:post, /graph\.instagram\.com/)
    end

    it 'maintains existing Instagram API functionality' do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })

      message = conversation.messages.create!(
        content: 'API compatibility test',
        message_type: :outgoing,
        account_id: account.id,
        inbox_id: inbox.id,
        additional_attributes: { skip_send_reply: true }
      )

      service = Instagram::RichMessageService.new(message: message, rich_payload: generic_payload)
      service.perform

      # Verify Instagram API was called with correct structure
      expect(WebMock).to have_requested(:post, /graph\.instagram\.com/)
        .with(body: hash_including(
          'recipient' => hash_including('id'),
          'message' => hash_including('attachment')
        ))
    end
  end

  describe 'unique message ID tracking for metrics' do
    before do
      allow(GlobalConfig).to receive(:get).with('SOCIALWISE_RICH_DASHBOARD')
                                          .and_return({ 'SOCIALWISE_RICH_DASHBOARD' => 'true' })
      allow(Rails.logger).to receive(:info)
    end

    it 'tracks message ID throughout the entire flow' do
      message = conversation.messages.create!(
        content: 'Metrics tracking test',
        message_type: :outgoing,
        account_id: account.id,
        inbox_id: inbox.id,
        additional_attributes: { skip_send_reply: true }
      )

      service = Instagram::RichMessageService.new(message: message, rich_payload: generic_payload)
      service.perform

      # Verify message ID is logged at key points
      expect(Rails.logger).to have_received(:info).with(
        "[SOCIALWISE-INSTAGRAM-RICH] Message ID: #{message.id}"
      ).at_least(:twice)

      # Verify message ID remains consistent
      message.reload
      expect(message.id).to be_present
      expect(message.id).to be_a(Integer)
    end
  end
end
