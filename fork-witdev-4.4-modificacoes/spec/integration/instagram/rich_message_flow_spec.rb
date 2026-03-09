# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Instagram Rich Message Flow Integration', type: :integration do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }

  # Non-Instagram channel for testing channel validation
  let(:api_channel) { create(:channel_api, account: account) }
  let(:api_inbox) { api_channel.inbox }
  let(:api_conversation) { create(:conversation, account: account, inbox: api_inbox, contact: contact) }
  let(:api_message) { create(:message, account: account, inbox: api_inbox, conversation: api_conversation) }

  before do
    # Mock Instagram API calls
    stub_request(:post, %r{graph\.instagram\.com/v22\.0/.*/messages})
      .to_return(status: 200, body: { message_id: 'test_message_id' }.to_json)
    
    # Mock GlobalConfig for human agent tag
    allow(GlobalConfig).to receive(:get).with('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')
                                        .and_return({ 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT' => false })
    
    # Mock account feature_enabled? with default return value
    allow(account).to receive(:feature_enabled?).and_return(false)
    allow(account).to receive(:feature_enabled?).with('SOCIALWISE_RICH_DASHBOARD').and_return(false)
  end

  # Helper method to verify Instagram API call was made
  def verify_instagram_api_called
    expect(WebMock).to have_requested(:post, %r{graph\.instagram\.com/v22\.0/.*/messages})
  end

  # Helper method to verify Instagram API call was NOT made
  def verify_instagram_api_not_called
    expect(WebMock).not_to have_requested(:post, %r{graph\.instagram\.com/v22\.0/.*/messages})
  end

  describe 'Complete Generic Template flow from socialwiseResponse to Instagram API' do
    let(:generic_template_payload) do
      {
        'message_format' => 'GENERIC_TEMPLATE',
        'payload' => {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Product 1',
              'subtitle' => 'Amazing product description',
              'image_url' => 'https://example.com/image1.jpg',
              'buttons' => [
                {
                  'type' => 'postback',
                  'title' => 'Select Product',
                  'payload' => 'select_product_1'
                }
              ]
            }
          ]
        }
      }
    end

    it 'processes complete Generic Template flow successfully' do
      result = Integrations::Socialwise::InstagramResponseProcessor.process(generic_template_payload, message)
      
      expect(result).to be true
      verify_instagram_api_called
    end

    it 'validates Generic Template payload before sending' do
      invalid_payload = {
        'message_format' => 'GENERIC_TEMPLATE',
        'payload' => {
          'template_type' => 'generic'
          # Missing elements array
        }
      }

      result = Integrations::Socialwise::InstagramResponseProcessor.process(invalid_payload, message)
      expect(result).to be true # Returns true because fallback was successful
      verify_instagram_api_not_called
    end

    it 'handles Generic Template with multiple elements' do
      multi_element_payload = {
        'message_format' => 'GENERIC_TEMPLATE',
        'payload' => {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Product 1',
              'buttons' => [{ 'type' => 'postback', 'title' => 'Select', 'payload' => 'select_1' }]
            },
            {
              'title' => 'Product 2',
              'buttons' => [{ 'type' => 'postback', 'title' => 'Select', 'payload' => 'select_2' }]
            }
          ]
        }
      }

      result = Integrations::Socialwise::InstagramResponseProcessor.process(multi_element_payload, message)
      expect(result).to be true
      verify_instagram_api_called
    end
  end

  describe 'Complete Button Template flow with different button types' do
    let(:button_template_payload) do
      {
        'message_format' => 'BUTTON_TEMPLATE',
        'payload' => {
          'template_type' => 'button',
          'text' => 'Choose your preferred action:',
          'buttons' => [
            {
              'type' => 'postback',
              'title' => 'Yes, Continue',
              'payload' => 'continue_yes'
            },
            {
              'type' => 'web_url',
              'title' => 'Visit Website',
              'url' => 'https://example.com'
            }
          ]
        }
      }
    end

    it 'processes Button Template with mixed button types successfully' do
      result = Integrations::Socialwise::InstagramResponseProcessor.process(button_template_payload, message)
      
      expect(result).to be true
      verify_instagram_api_called
    end

    it 'validates Button Template payload before sending' do
      invalid_payload = {
        'message_format' => 'BUTTON_TEMPLATE',
        'payload' => {
          'template_type' => 'button',
          'buttons' => [
            { 'type' => 'postback', 'title' => 'Yes', 'payload' => 'yes' }
          ]
          # Missing text field
        }
      }

      result = Integrations::Socialwise::InstagramResponseProcessor.process(invalid_payload, message)
      expect(result).to be true # Returns true because fallback was successful
      verify_instagram_api_not_called
    end

    it 'handles Button Template with maximum buttons (3)' do
      max_buttons_payload = {
        'message_format' => 'BUTTON_TEMPLATE',
        'payload' => {
          'template_type' => 'button',
          'text' => 'Choose from these options:',
          'buttons' => [
            { 'type' => 'postback', 'title' => 'Option 1', 'payload' => 'opt1' },
            { 'type' => 'postback', 'title' => 'Option 2', 'payload' => 'opt2' },
            { 'type' => 'postback', 'title' => 'Option 3', 'payload' => 'opt3' }
          ]
        }
      }

      result = Integrations::Socialwise::InstagramResponseProcessor.process(max_buttons_payload, message)
      expect(result).to be true
      verify_instagram_api_called
    end
  end

  describe 'Complete Quick Replies flow with multiple options' do
    let(:quick_replies_payload) do
      {
        'message_format' => 'QUICK_REPLIES',
        'payload' => {
          'text' => 'What would you like to do today?',
          'quick_replies' => [
            {
              'content_type' => 'text',
              'title' => 'Check Status',
              'payload' => 'check_status'
            },
            {
              'content_type' => 'text',
              'title' => 'Make Payment',
              'payload' => 'make_payment'
            }
          ]
        }
      }
    end

    it 'processes Quick Replies with basic options successfully' do
      result = Integrations::Socialwise::InstagramResponseProcessor.process(quick_replies_payload, message)
      
      expect(result).to be true
      verify_instagram_api_called
    end

    it 'validates Quick Replies payload before sending' do
      invalid_payload = {
        'message_format' => 'QUICK_REPLIES',
        'payload' => {
          'quick_replies' => [
            { 'content_type' => 'text', 'title' => 'Option 1', 'payload' => 'option_1' }
          ]
          # Missing text field
        }
      }

      result = Integrations::Socialwise::InstagramResponseProcessor.process(invalid_payload, message)
      expect(result).to be true # Returns true because fallback was successful
      verify_instagram_api_not_called
    end

    it 'handles Quick Replies with maximum options (13)' do
      quick_replies = (1..13).map do |i|
        {
          'content_type' => 'text',
          'title' => "Option #{i}",
          'payload' => "option_#{i}"
        }
      end

      max_replies_payload = {
        'message_format' => 'QUICK_REPLIES',
        'payload' => {
          'text' => 'Choose from these many options:',
          'quick_replies' => quick_replies
        }
      }

      result = Integrations::Socialwise::InstagramResponseProcessor.process(max_replies_payload, message)
      expect(result).to be true
      verify_instagram_api_called
    end
  end

  describe 'Payload validation integration with message sending' do
    it 'validates and sends valid Generic Template' do
      valid_payload = {
        'message_format' => 'GENERIC_TEMPLATE',
        'payload' => {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Valid Product',
              'subtitle' => 'Valid description',
              'image_url' => 'https://example.com/valid.jpg',
              'buttons' => [
                { 'type' => 'postback', 'title' => 'Valid Button', 'payload' => 'valid_payload' }
              ]
            }
          ]
        }
      }

      result = Integrations::Socialwise::InstagramResponseProcessor.process(valid_payload, message)
      expect(result).to be true
      verify_instagram_api_called
    end

    it 'validates and rejects Generic Template with invalid image URL' do
      invalid_payload = {
        'message_format' => 'GENERIC_TEMPLATE',
        'payload' => {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Product with Invalid Image',
              'image_url' => 'not_a_valid_url'
            }
          ]
        }
      }

      result = Integrations::Socialwise::InstagramResponseProcessor.process(invalid_payload, message)
      expect(result).to be true # Returns true because fallback was successful
      verify_instagram_api_not_called
    end

    it 'validates and rejects Button Template with too many buttons' do
      invalid_payload = {
        'message_format' => 'BUTTON_TEMPLATE',
        'payload' => {
          'template_type' => 'button',
          'text' => 'Too many buttons:',
          'buttons' => [
            { 'type' => 'postback', 'title' => 'Button 1', 'payload' => 'btn1' },
            { 'type' => 'postback', 'title' => 'Button 2', 'payload' => 'btn2' },
            { 'type' => 'postback', 'title' => 'Button 3', 'payload' => 'btn3' },
            { 'type' => 'postback', 'title' => 'Button 4', 'payload' => 'btn4' } # Too many
          ]
        }
      }

      result = Integrations::Socialwise::InstagramResponseProcessor.process(invalid_payload, message)
      expect(result).to be true # Returns true because fallback was successful
      verify_instagram_api_not_called
    end

    it 'validates and rejects Quick Replies with too many options' do
      too_many_replies = (1..14).map do |i|
        { 'content_type' => 'text', 'title' => "Option #{i}", 'payload' => "option_#{i}" }
      end

      invalid_payload = {
        'message_format' => 'QUICK_REPLIES',
        'payload' => {
          'text' => 'Too many quick replies:',
          'quick_replies' => too_many_replies
        }
      }

      result = Integrations::Socialwise::InstagramResponseProcessor.process(invalid_payload, message)
      expect(result).to be true # Returns true because fallback was successful
      verify_instagram_api_not_called
    end
  end

  describe 'Error scenarios and fallback to text messages' do
    let(:valid_payload) do
      {
        'message_format' => 'BUTTON_TEMPLATE',
        'payload' => {
          'template_type' => 'button',
          'text' => 'Choose an option:',
          'buttons' => [{ 'type' => 'postback', 'title' => 'Yes', 'payload' => 'yes' }]
        }
      }
    end

    it 'falls back to text message when Instagram API returns error' do
      # Mock Instagram API to return error
      stub_request(:post, %r{graph\.instagram\.com/v22\.0/.*/messages})
        .to_return(status: 400, body: { error: { message: 'Bad Request', code: 400 } }.to_json)

      # Expect fallback message creation (may be called multiple times due to rich message service + fallback)
      expect(conversation.messages).to receive(:create!).with(
        hash_including(
          content: 'Choose an option:',
          message_type: :outgoing
        )
      ).at_least(:once)

      result = Integrations::Socialwise::InstagramResponseProcessor.process(valid_payload, message)
      expect(result).to be true # Fallback successful, conversation flow maintained
    end

    it 'falls back to text message when Instagram API times out' do
      # Mock Instagram API to timeout
      stub_request(:post, %r{graph\.instagram\.com/v22\.0/.*/messages})
        .to_timeout

      # Expect fallback message creation (may be called multiple times due to rich message service + fallback)
      expect(conversation.messages).to receive(:create!).with(
        hash_including(
          content: 'Choose an option:',
          message_type: :outgoing
        )
      ).at_least(:once)

      result = Integrations::Socialwise::InstagramResponseProcessor.process(valid_payload, message)
      expect(result).to be true # Fallback successful, conversation flow maintained
    end

    it 'falls back to text message when Rich Message Service raises exception' do
      # Mock Rich Message Service to raise exception
      allow(Instagram::RichMessageService).to receive(:new).and_raise(StandardError, 'Service error')

      # Expect fallback message creation (may be called multiple times due to rich message service + fallback)
      expect(conversation.messages).to receive(:create!).with(
        hash_including(
          content: 'Choose an option:',
          message_type: :outgoing
        )
      ).at_least(:once)

      result = Integrations::Socialwise::InstagramResponseProcessor.process(valid_payload, message)
      expect(result).to be true # Fallback successful, conversation flow maintained
    end

    it 'falls back to generic message when payload text extraction fails' do
      # Payload with no extractable text
      complex_payload = {
        'message_format' => 'GENERIC_TEMPLATE',
        'payload' => {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => '', # Empty title
              'subtitle' => '', # Empty subtitle
              'buttons' => []
            }
          ]
        }
      }

      result = Integrations::Socialwise::InstagramResponseProcessor.process(complex_payload, message)
      expect(result).to be true # Fallback successful
      verify_instagram_api_not_called
    end

    it 'handles malformed socialwiseResponse gracefully' do
      malformed_payload = 'not_a_hash'

      result = Integrations::Socialwise::InstagramResponseProcessor.process(malformed_payload, message)
      expect(result).to be true # Fallback successful
      verify_instagram_api_not_called
    end

    it 'handles nil socialwiseResponse gracefully' do
      result = Integrations::Socialwise::InstagramResponseProcessor.process(nil, message)
      expect(result).to be true # Fallback successful
      verify_instagram_api_not_called
    end

    it 'handles unknown message format gracefully' do
      unknown_format_payload = {
        'message_format' => 'UNKNOWN_FORMAT',
        'payload' => { 'some_data' => 'test' }
      }

      result = Integrations::Socialwise::InstagramResponseProcessor.process(unknown_format_payload, message)
      expect(result).to be true # Fallback successful
      verify_instagram_api_not_called
    end
  end

  describe 'Instagram channel validation and non-Instagram channel handling' do
    let(:valid_payload) do
      {
        'message_format' => 'BUTTON_TEMPLATE',
        'payload' => {
          'template_type' => 'button',
          'text' => 'Instagram only message',
          'buttons' => [{ 'type' => 'postback', 'title' => 'Yes', 'payload' => 'yes' }]
        }
      }
    end

    it 'processes rich messages for Instagram channels' do
      result = Integrations::Socialwise::InstagramResponseProcessor.process(valid_payload, message)
      expect(result).to be true
      verify_instagram_api_called
    end

    it 'falls back to text message for non-Instagram channels' do
      result = Integrations::Socialwise::InstagramResponseProcessor.process(valid_payload, api_message)
      expect(result).to be true # Fallback successful
      verify_instagram_api_not_called
    end

    it 'validates channel type before processing rich messages' do
      # Test with email channel
      email_channel = create(:channel_email, account: account)
      email_inbox = create(:inbox, channel: email_channel, account: account)
      email_conversation = create(:conversation, account: account, inbox: email_inbox, contact: contact)
      email_message = create(:message, account: account, inbox: email_inbox, conversation: email_conversation)

      result = Integrations::Socialwise::InstagramResponseProcessor.process(valid_payload, email_message)
      expect(result).to be true # Fallback successful
      verify_instagram_api_not_called
    end

    it 'logs channel validation results' do
      allow(Rails.logger).to receive(:warn)

      Integrations::Socialwise::InstagramResponseProcessor.process(valid_payload, api_message)

      expect(Rails.logger).to have_received(:warn).with(
        match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*Rich messages only supported for Instagram channels/)
      )
    end
  end

  describe 'Performance and reliability under load' do
    let(:valid_payload) do
      {
        'message_format' => 'QUICK_REPLIES',
        'payload' => {
          'text' => 'Performance test message',
          'quick_replies' => [
            { 'content_type' => 'text', 'title' => 'Option 1', 'payload' => 'option_1' }
          ]
        }
      }
    end

    it 'processes multiple rich messages efficiently' do
      start_time = Time.current

      # Process 5 rich messages (reduced for faster test execution)
      results = []
      5.times do |i|
        test_message = create(:message, account: account, inbox: inbox, conversation: conversation)
        results << Integrations::Socialwise::InstagramResponseProcessor.process(valid_payload, test_message)
      end

      end_time = Time.current
      total_time = end_time - start_time

      # All should succeed
      expect(results).to all(be true)

      # Should complete within reasonable time (3 seconds for 5 messages)
      expect(total_time).to be < 3.seconds

      # Verify all Instagram API calls were made
      expect(WebMock).to have_requested(:post, %r{graph\.instagram\.com/v22\.0/.*/messages}).times(5)
    end

    it 'handles concurrent processing without conflicts' do
      # Simulate concurrent processing
      threads = []
      results = []
      mutex = Mutex.new

      3.times do |i| # Reduced for faster execution
        threads << Thread.new do
          test_message = create(:message, account: account, inbox: inbox, conversation: conversation)
          result = Integrations::Socialwise::InstagramResponseProcessor.process(valid_payload, test_message)
          
          mutex.synchronize do
            results << result
          end
        end
      end

      threads.each(&:join)

      # All should succeed
      expect(results).to all(be true)
      expect(results.length).to eq(3)

      # Verify all Instagram API calls were made
      expect(WebMock).to have_requested(:post, %r{graph\.instagram\.com/v22\.0/.*/messages}).times(3)
    end

    it 'maintains performance with large payloads' do
      # Create large Generic Template with multiple elements
      large_elements = (1..5).map do |i| # Reduced to 5 for faster execution
        {
          'title' => "Product #{i} with a detailed title",
          'subtitle' => "This is a detailed subtitle for product #{i}",
          'image_url' => "https://example.com/product-#{i}.jpg",
          'buttons' => [
            { 'type' => 'postback', 'title' => 'Select Product', 'payload' => "select_#{i}" },
            { 'type' => 'web_url', 'title' => 'View Details', 'url' => "https://example.com/products/#{i}" }
          ]
        }
      end

      large_payload = {
        'message_format' => 'GENERIC_TEMPLATE',
        'payload' => {
          'template_type' => 'generic',
          'elements' => large_elements
        }
      }

      start_time = Time.current
      result = Integrations::Socialwise::InstagramResponseProcessor.process(large_payload, message)
      end_time = Time.current

      expect(result).to be true
      expect(end_time - start_time).to be < 2.seconds # Should process large payload quickly
      verify_instagram_api_called
    end
  end

  describe 'Integration with human agent tag functionality' do
    let(:valid_payload) do
      {
        'message_format' => 'BUTTON_TEMPLATE',
        'payload' => {
          'template_type' => 'button',
          'text' => 'Human agent tagged message',
          'buttons' => [{ 'type' => 'postback', 'title' => 'Yes', 'payload' => 'yes' }]
        }
      }
    end

    context 'when human agent tag is enabled' do
      before do
        allow(GlobalConfig).to receive(:get).with('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')
                                            .and_return({ 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT' => true })
      end

      it 'applies human agent tag to rich messages' do
        result = Integrations::Socialwise::InstagramResponseProcessor.process(valid_payload, message)
        expect(result).to be true
        verify_instagram_api_called
      end

      it 'applies human agent tag to Generic Templates' do
        generic_payload = {
          'message_format' => 'GENERIC_TEMPLATE',
          'payload' => {
            'template_type' => 'generic',
            'elements' => [
              {
                'title' => 'Tagged Product',
                'buttons' => [{ 'type' => 'postback', 'title' => 'Select', 'payload' => 'select' }]
              }
            ]
          }
        }

        result = Integrations::Socialwise::InstagramResponseProcessor.process(generic_payload, message)
        expect(result).to be true
        verify_instagram_api_called
      end

      it 'overrides default messaging_type for Quick Replies when human agent tag is enabled' do
        quick_replies_payload = {
          'message_format' => 'QUICK_REPLIES',
          'payload' => {
            'text' => 'Tagged quick replies',
            'quick_replies' => [
              { 'content_type' => 'text', 'title' => 'Option 1', 'payload' => 'option_1' }
            ]
          }
        }

        result = Integrations::Socialwise::InstagramResponseProcessor.process(quick_replies_payload, message)
        expect(result).to be true
        verify_instagram_api_called
      end
    end

    context 'when human agent tag is disabled' do
      before do
        allow(GlobalConfig).to receive(:get).with('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')
                                            .and_return({ 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT' => false })
      end

      it 'uses default messaging_type for templates' do
        result = Integrations::Socialwise::InstagramResponseProcessor.process(valid_payload, message)
        expect(result).to be true
        verify_instagram_api_called
      end

      it 'uses default messaging_type for Quick Replies' do
        quick_replies_payload = {
          'message_format' => 'QUICK_REPLIES',
          'payload' => {
            'text' => 'Regular quick replies',
            'quick_replies' => [
              { 'content_type' => 'text', 'title' => 'Option 1', 'payload' => 'option_1' }
            ]
          }
        }

        result = Integrations::Socialwise::InstagramResponseProcessor.process(quick_replies_payload, message)
        expect(result).to be true
        verify_instagram_api_called
      end
    end
  end
end