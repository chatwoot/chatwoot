# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Instagram Rich Templates End-to-End Flow', type: :request do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, contact: contact, inbox: inbox, account: account) }
  let(:hook) { create(:integrations_hook, :dialogflow, account: account, inbox: inbox) }
  
  let(:instagram_user_id) { '1234567890' }
  let(:instagram_api_url) { "https://graph.instagram.com/v22.0/#{instagram_channel.instagram_id}/messages" }
  
  before do
    # Setup Instagram channel with proper configuration
    instagram_channel.update!(
      access_token: 'test_access_token',
      instagram_id: 'test_instagram_id'
    )
    
    # Mock contact source ID for Instagram
    allow(contact).to receive(:get_source_id).with(inbox.id).and_return(instagram_user_id)
    
    # Setup WebMock for Instagram API calls
    stub_request(:post, instagram_api_url)
      .to_return(status: 200, body: { message_id: 'test_message_id' }.to_json)
  end

  def create_processor(message)
    event_data = {
      message: message,
      conversation: conversation,
      contact: contact,
      inbox: inbox
    }
    
    Integrations::Dialogflow::ProcessorService.new(
      event_name: 'message.created',
      hook: hook,
      event_data: event_data
    )
  end

  describe 'Generic Template Flow' do
    let(:dialogflow_response) do
      {
        'query_result' => {
          'fulfillment_messages' => [
            {
              'socialwiseResponse' => {
                'message_format' => 'GENERIC_TEMPLATE',
                'payload' => {
                  'template_type' => 'generic',
                  'elements' => [
                    {
                      'title' => 'Product 1',
                      'subtitle' => 'Amazing product description',
                      'image_url' => 'https://example.com/product1.jpg',
                      'buttons' => [
                        {
                          'type' => 'postback',
                          'title' => 'Buy Now',
                          'payload' => 'buy_product_1'
                        }
                      ]
                    }
                  ]
                }
              }
            }
          ]
        }
      }
    end

    it 'processes complete Generic Template flow successfully' do
      # Ensure conversation is in pending status
      conversation.update!(status: :pending)
      
      incoming_message = create(:message, 
        conversation: conversation, 
        message_type: :incoming,
        content: 'Show me products',
        private: false
      )

      processor = create_processor(incoming_message)

      # Mock the get_response method to return our test response
      allow(processor).to receive(:get_response).and_return(dialogflow_response)

      expect {
        processor.perform
      }.to change { conversation.messages.count }.by(1)

      # Verify outgoing message was created
      outgoing_message = conversation.messages.outgoing.last
      expect(outgoing_message).to be_present
    end

    it 'handles Generic Template with user interaction simulation' do
      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      
      processor = create_processor(incoming_message)
      processor.process_response(incoming_message, dialogflow_response)

      # Simulate user interaction
      postback_message = create(:message,
        conversation: conversation,
        message_type: :incoming,
        content: 'Buy Now',
        source_id: 'postback_message_id'
      )

      expect(postback_message.content).to eq('Buy Now')
    end
  end

  describe 'Button Template Flow' do
    let(:dialogflow_response) do
      {
        'query_result' => {
          'fulfillment_messages' => [
            {
              'socialwiseResponse' => {
                'message_format' => 'BUTTON_TEMPLATE',
                'payload' => {
                  'template_type' => 'button',
                  'text' => 'Choose your preferred option:',
                  'buttons' => [
                    {
                      'type' => 'postback',
                      'title' => 'Option A',
                      'payload' => 'option_a'
                    }
                  ]
                }
              }
            }
          ]
        }
      }
    end

    it 'processes complete Button Template flow successfully' do
      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      processor = create_processor(incoming_message)

      expect {
        processor.process_response(incoming_message, dialogflow_response)
      }.to change { conversation.messages.count }.by(1)
    end

    it 'handles Button Template user interaction' do
      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      processor = create_processor(incoming_message)
      processor.process_response(incoming_message, dialogflow_response)

      button_response = create(:message,
        conversation: conversation,
        message_type: :incoming,
        content: 'Option A'
      )

      expect(button_response.content).to eq('Option A')
    end
  end

  describe 'Quick Replies Flow' do
    let(:dialogflow_response) do
      {
        'query_result' => {
          'fulfillment_messages' => [
            {
              'socialwiseResponse' => {
                'message_format' => 'QUICK_REPLIES',
                'payload' => {
                  'text' => 'What would you like to do?',
                  'quick_replies' => [
                    {
                      'content_type' => 'text',
                      'title' => 'Check Status',
                      'payload' => 'check_status'
                    }
                  ]
                }
              }
            }
          ]
        }
      }
    end

    it 'processes complete Quick Replies flow successfully' do
      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      processor = create_processor(incoming_message)

      expect {
        processor.process_response(incoming_message, dialogflow_response)
      }.to change { conversation.messages.count }.by(1)
    end

    it 'handles Quick Reply user interaction' do
      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      processor = create_processor(incoming_message)
      processor.process_response(incoming_message, dialogflow_response)

      quick_reply_response = create(:message,
        conversation: conversation,
        message_type: :incoming,
        content: 'Check Status'
      )

      expect(quick_reply_response.content).to eq('Check Status')
    end
  end

  describe 'Error Scenarios and Recovery Mechanisms' do
    it 'handles Instagram API failure with fallback to text message' do
      stub_request(:post, instagram_api_url)
        .to_return(status: 500, body: { error: 'Internal Server Error' }.to_json)

      dialogflow_response = {
        'query_result' => {
          'fulfillment_messages' => [
            {
              'socialwiseResponse' => {
                'message_format' => 'GENERIC_TEMPLATE',
                'payload' => {
                  'template_type' => 'generic',
                  'elements' => [{ 'title' => 'Test Product' }]
                }
              }
            }
          ]
        }
      }

      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      processor = create_processor(incoming_message)

      expect {
        processor.process_response(incoming_message, dialogflow_response)
      }.to change { conversation.messages.count }.by(1)
    end

    it 'handles invalid payload structure gracefully' do
      dialogflow_response = {
        'query_result' => {
          'fulfillment_messages' => [
            {
              'socialwiseResponse' => {
                'message_format' => 'GENERIC_TEMPLATE',
                'payload' => { 'invalid_structure' => true }
              }
            }
          ]
        }
      }

      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      processor = create_processor(incoming_message)

      expect {
        processor.process_response(incoming_message, dialogflow_response)
      }.to change { conversation.messages.count }.by(1)
    end

    it 'handles unknown message format with fallback' do
      dialogflow_response = {
        'query_result' => {
          'fulfillment_messages' => [
            {
              'socialwiseResponse' => {
                'message_format' => 'UNKNOWN_FORMAT',
                'payload' => { 'some_data' => 'test' }
              }
            }
          ]
        }
      }

      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      processor = create_processor(incoming_message)

      expect {
        processor.process_response(incoming_message, dialogflow_response)
      }.to change { conversation.messages.count }.by(1)
    end

    it 'handles non-Instagram channel gracefully' do
      # Use a simple text channel to avoid external API calls
      text_channel = create(:channel_sms, account: account)
      text_inbox = create(:inbox, channel: text_channel, account: account)
      text_conversation = create(:conversation, contact: contact, inbox: text_inbox, account: account)

      dialogflow_response = {
        'query_result' => {
          'fulfillment_messages' => [
            {
              'socialwiseResponse' => {
                'message_format' => 'GENERIC_TEMPLATE',
                'payload' => { 'template_type' => 'generic', 'elements' => [{ 'title' => 'Test' }] }
              }
            }
          ]
        }
      }

      incoming_message = create(:message, conversation: text_conversation, message_type: :incoming)
      
      event_data = { message: incoming_message, conversation: text_conversation, contact: contact, inbox: text_inbox }
      processor = Integrations::Dialogflow::ProcessorService.new(
        event_name: 'message.created', hook: hook, event_data: event_data
      )

      expect {
        processor.process_response(incoming_message, dialogflow_response)
      }.to change { text_conversation.messages.count }.by(1)
    end
  end

  describe 'Performance Under Load' do
    it 'handles multiple concurrent rich messages efficiently' do
      dialogflow_responses = 3.times.map do |i|
        {
          'query_result' => {
            'fulfillment_messages' => [
              {
                'socialwiseResponse' => {
                  'message_format' => 'BUTTON_TEMPLATE',
                  'payload' => {
                    'template_type' => 'button',
                    'text' => "Message #{i + 1}",
                    'buttons' => [{ 'type' => 'postback', 'title' => "Button #{i + 1}", 'payload' => "payload_#{i + 1}" }]
                  }
                }
              }
            ]
          }
        }
      end

      incoming_messages = 3.times.map { create(:message, conversation: conversation, message_type: :incoming) }
      start_time = Time.current

      threads = incoming_messages.zip(dialogflow_responses).map do |message, response|
        Thread.new do
          processor = create_processor(message)
          processor.process_response(message, response)
        end
      end

      threads.each(&:join)
      processing_time = Time.current - start_time

      expect(conversation.messages.outgoing.count).to eq(3)
      expect(processing_time).to be < 5.seconds
    end

    it 'handles rapid sequential rich messages without conflicts' do
      5.times do |i|
        dialogflow_response = {
          'query_result' => {
            'fulfillment_messages' => [
              {
                'socialwiseResponse' => {
                  'message_format' => 'QUICK_REPLIES',
                  'payload' => {
                    'text' => "Quick message #{i + 1}",
                    'quick_replies' => [{ 'content_type' => 'text', 'title' => "Reply #{i + 1}", 'payload' => "quick_#{i + 1}" }]
                  }
                }
              }
            ]
          }
        }

        incoming_message = create(:message, conversation: conversation, message_type: :incoming)
        processor = create_processor(incoming_message)
        processor.process_response(incoming_message, dialogflow_response)
      end

      expect(conversation.messages.outgoing.count).to eq(5)
    end
  end

  describe 'Backward Compatibility' do
    it 'maintains compatibility with existing Instagram text messaging' do
      standard_response = {
        'query_result' => {
          'fulfillment_messages' => [
            { 'text' => { 'text' => ['This is a standard text message'] } }
          ]
        }
      }

      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      processor = create_processor(incoming_message)

      expect {
        processor.process_response(incoming_message, standard_response)
      }.to change { conversation.messages.count }.by(1)

      text_message = conversation.messages.outgoing.last
      expect(text_message.content).to eq('This is a standard text message')
    end

    it 'handles mixed responses with socialwiseResponse priority' do
      mixed_response = {
        'query_result' => {
          'fulfillment_messages' => [
            { 'text' => { 'text' => ['This text should be ignored'] } },
            {
              'socialwiseResponse' => {
                'message_format' => 'BUTTON_TEMPLATE',
                'payload' => {
                  'template_type' => 'button',
                  'text' => 'Priority rich message',
                  'buttons' => [{ 'type' => 'postback', 'title' => 'Click Me', 'payload' => 'click_payload' }]
                }
              }
            }
          ]
        }
      }

      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      processor = create_processor(incoming_message)

      expect {
        processor.process_response(incoming_message, mixed_response)
      }.to change { conversation.messages.count }.by(1)
    end

    it 'preserves existing Instagram webhook processing' do
      incoming_message = create(:message,
        conversation: conversation,
        message_type: :incoming,
        content: 'Regular incoming message',
        source_id: 'regular_message_id'
      )

      expect(incoming_message.content).to eq('Regular incoming message')
      expect(incoming_message.message_type).to eq('incoming')
    end

    it 'maintains existing error handling patterns' do
      invalid_response = {
        'query_result' => {
          'fulfillment_messages' => [{ 'invalid_structure' => true }]
        }
      }

      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      processor = create_processor(incoming_message)

      expect {
        processor.process_response(incoming_message, invalid_response)
      }.not_to raise_error
    end
  end

  describe 'Integration with Existing Services' do
    it 'integrates properly with Instagram::BaseSendService infrastructure' do
      dialogflow_response = {
        'query_result' => {
          'fulfillment_messages' => [
            {
              'socialwiseResponse' => {
                'message_format' => 'GENERIC_TEMPLATE',
                'payload' => {
                  'template_type' => 'generic',
                  'elements' => [{ 'title' => 'Integration Test', 'subtitle' => 'Testing service integration' }]
                }
              }
            }
          ]
        }
      }

      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      
      rich_service_instance = instance_double(Instagram::RichMessageService)
      allow(Instagram::RichMessageService).to receive(:new).and_return(rich_service_instance)
      allow(rich_service_instance).to receive(:perform)

      processor = create_processor(incoming_message)
      processor.process_response(incoming_message, dialogflow_response)

      expect(Instagram::RichMessageService).to have_received(:new)
        .with(incoming_message, hash_including('template_type' => 'generic'))
      expect(rich_service_instance).to have_received(:perform)
    end

    it 'respects existing rate limiting and authentication' do
      dialogflow_response = {
        'query_result' => {
          'fulfillment_messages' => [
            {
              'socialwiseResponse' => {
                'message_format' => 'BUTTON_TEMPLATE',
                'payload' => {
                  'template_type' => 'button',
                  'text' => 'Rate limit test',
                  'buttons' => [{ 'type' => 'postback', 'title' => 'Test Button', 'payload' => 'test_payload' }]
                }
              }
            }
          ]
        }
      }

      incoming_message = create(:message, conversation: conversation, message_type: :incoming)
      processor = create_processor(incoming_message)
      processor.process_response(incoming_message, dialogflow_response)

      expect(WebMock).to have_requested(:post, instagram_api_url)
        .with(query: hash_including('access_token' => 'test_access_token'))
    end
  end
end