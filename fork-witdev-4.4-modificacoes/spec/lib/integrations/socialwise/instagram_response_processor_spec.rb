# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::Socialwise::InstagramResponseProcessor do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }

  # Non-Instagram channel for testing channel validation
  let(:web_widget_channel) { create(:channel_web_widget, account: account) }
  let(:web_inbox) { create(:inbox, channel: web_widget_channel, account: account) }
  let(:web_conversation) { create(:conversation, account: account, inbox: web_inbox, contact: contact) }
  let(:web_message) { create(:message, account: account, inbox: web_inbox, conversation: web_conversation) }

  describe '.process' do
    context 'with valid socialwiseResponse data' do
      let(:generic_template_payload) do
        {
          'message_format' => 'GENERIC_TEMPLATE',
          'payload' => {
            'template_type' => 'generic',
            'elements' => [
              {
                'title' => 'Card Title',
                'subtitle' => 'Card Subtitle',
                'image_url' => 'https://example.com/image.jpg',
                'buttons' => [
                  {
                    'type' => 'postback',
                    'title' => 'Select',
                    'payload' => 'select_card'
                  }
                ]
              }
            ]
          }
        }
      end

      let(:button_template_payload) do
        {
          'message_format' => 'BUTTON_TEMPLATE',
          'payload' => {
            'template_type' => 'button',
            'text' => 'Choose an option:',
            'buttons' => [
              {
                'type' => 'postback',
                'title' => 'Option 1',
                'payload' => 'option_1'
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

      let(:quick_replies_payload) do
        {
          'message_format' => 'QUICK_REPLIES',
          'payload' => {
            'text' => 'Select an option:',
            'quick_replies' => [
              {
                'content_type' => 'text',
                'title' => 'Option 1',
                'payload' => 'option_1'
              },
              {
                'content_type' => 'text',
                'title' => 'Option 2',
                'payload' => 'option_2'
              }
            ]
          }
        }
      end

      it 'processes Generic Template successfully' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform)

        result = described_class.process(generic_template_payload, message)

        expect(result).to be true
        expect(Instagram::RichMessageService).to have_received(:new)
        expect(rich_message_service).to have_received(:perform)
      end

      it 'processes Button Template successfully' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform)

        result = described_class.process(button_template_payload, message)

        expect(result).to be true
        expect(Instagram::RichMessageService).to have_received(:new)
        expect(rich_message_service).to have_received(:perform)
      end

      it 'processes Quick Replies successfully' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform)

        result = described_class.process(quick_replies_payload, message)

        expect(result).to be true
        expect(Instagram::RichMessageService).to have_received(:new)
        expect(rich_message_service).to have_received(:perform)
      end

      it 'logs processing details' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform)
        allow(Rails.logger).to receive(:info)

        described_class.process(button_template_payload, message)

        expect(Rails.logger).to have_received(:info).with(match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*STARTING SOCIALWISE RESPONSE PROCESSING/))
        expect(Rails.logger).to have_received(:info).with(match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*Message format: BUTTON_TEMPLATE/))
      end
    end

    context 'with invalid socialwiseResponse data' do
      it 'handles non-Hash socialwise_data' do
        expect(conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Message received',
            message_type: :outgoing
          )
        )

        result = described_class.process('invalid_data', message)
        expect(result).to be true
      end

      it 'handles nil socialwise_data' do
        expect(conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Message received',
            message_type: :outgoing
          )
        )

        result = described_class.process(nil, message)
        expect(result).to be true
      end

      it 'handles empty socialwise_data' do
        expect(conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Message received',
            message_type: :outgoing
          )
        )

        result = described_class.process({}, message)
        expect(result).to be true
      end
    end

    context 'with error handling scenarios' do
      let(:valid_payload) do
        {
          'message_format' => 'BUTTON_TEMPLATE',
          'payload' => {
            'template_type' => 'button',
            'text' => 'Choose an option:',
            'buttons' => [
              {
                'type' => 'postback',
                'title' => 'Option 1',
                'payload' => 'option_1'
              }
            ]
          }
        }
      end

      it 'handles Instagram Rich Message Service errors gracefully' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform).and_raise(StandardError, 'API Error')

        expect(conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Choose an option:',
            message_type: :outgoing
          )
        )

        result = described_class.process(valid_payload, message)
        expect(result).to be false
      end

      it 'logs error details when processing fails' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform).and_raise(StandardError, 'API Error')
        allow(Rails.logger).to receive(:error)
        allow(conversation.messages).to receive(:create!)

        described_class.process(valid_payload, message)

        expect(Rails.logger).to have_received(:error).with(match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*Processing failed.*API Error/))
      end

      it 'returns false when processing fails' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform).and_raise(StandardError, 'API Error')
        allow(conversation.messages).to receive(:create!)

        result = described_class.process(valid_payload, message)
        expect(result).to be false
      end
    end

    context 'with unknown message format handling' do
      let(:unknown_format_payload) do
        {
          'message_format' => 'UNKNOWN_FORMAT',
          'payload' => {
            'some_data' => 'test'
          }
        }
      end

      it 'handles unknown message formats gracefully' do
        expect(conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Message received',
            message_type: :outgoing
          )
        )

        result = described_class.process(unknown_format_payload, message)
        expect(result).to be true
      end

      it 'logs warning for unknown message formats' do
        allow(Rails.logger).to receive(:warn)
        allow(conversation.messages).to receive(:create!)

        described_class.process(unknown_format_payload, message)

        expect(Rails.logger).to have_received(:warn).with(match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*Unknown message format: UNKNOWN_FORMAT/))
      end
    end

    context 'with Instagram channel validation' do
      let(:valid_payload) do
        {
          'message_format' => 'BUTTON_TEMPLATE',
          'payload' => {
            'template_type' => 'button',
            'text' => 'Choose an option:',
            'buttons' => [
              {
                'type' => 'postback',
                'title' => 'Option 1',
                'payload' => 'option_1'
              }
            ]
          }
        }
      end

      it 'processes messages for Instagram channels' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform)

        result = described_class.process(valid_payload, message)

        expect(result).to be true
        expect(Instagram::RichMessageService).to have_received(:new)
      end

      it 'falls back to text message for non-Instagram channels' do
        expect(web_conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Choose an option:',
            message_type: :outgoing
          )
        )

        result = described_class.process(valid_payload, web_message)
        expect(result).to be true
      end

      it 'logs warning for non-Instagram channels' do
        allow(Rails.logger).to receive(:warn)
        allow(web_conversation.messages).to receive(:create!)

        described_class.process(valid_payload, web_message)

        expect(Rails.logger).to have_received(:warn).with(match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*Rich messages only supported for Instagram channels/))
      end
    end
  end

  describe '.route_message' do
    let(:valid_generic_payload) do
      {
        'template_type' => 'generic',
        'elements' => [
          {
            'title' => 'Card Title',
            'buttons' => [
              {
                'type' => 'postback',
                'title' => 'Select',
                'payload' => 'select_card'
              }
            ]
          }
        ]
      }
    end

    let(:valid_button_payload) do
      {
        'template_type' => 'button',
        'text' => 'Choose an option:',
        'buttons' => [
          {
            'type' => 'postback',
            'title' => 'Option 1',
            'payload' => 'option_1'
          }
        ]
      }
    end

    let(:valid_quick_replies_payload) do
      {
        'text' => 'Select an option:',
        'quick_replies' => [
          {
            'content_type' => 'text',
            'title' => 'Option 1',
            'payload' => 'option_1'
          }
        ]
      }
    end

    it 'routes GENERIC_TEMPLATE to send_generic_template' do
      expect(described_class).to receive(:send_generic_template).with(valid_generic_payload, message)

      described_class.send(:route_message, 'GENERIC_TEMPLATE', valid_generic_payload, message)
    end

    it 'routes BUTTON_TEMPLATE to send_button_template' do
      expect(described_class).to receive(:send_button_template).with(valid_button_payload, message)

      described_class.send(:route_message, 'BUTTON_TEMPLATE', valid_button_payload, message)
    end

    it 'routes QUICK_REPLIES to send_quick_replies' do
      expect(described_class).to receive(:send_quick_replies).with(valid_quick_replies_payload, message)

      described_class.send(:route_message, 'QUICK_REPLIES', valid_quick_replies_payload, message)
    end

    it 'handles unknown message formats' do
      expect(described_class).to receive(:log_unknown_format).with('UNKNOWN_FORMAT')
      expect(described_class).to receive(:fallback_to_text_message).with(message, { 'payload' => valid_button_payload })

      described_class.send(:route_message, 'UNKNOWN_FORMAT', valid_button_payload, message)
    end

    it 'validates Instagram channel before routing' do
      allow(Rails.logger).to receive(:warn)
      expect(described_class).to receive(:fallback_to_text_message).with(web_message, { 'payload' => valid_button_payload })

      described_class.send(:route_message, 'BUTTON_TEMPLATE', valid_button_payload, web_message)
    end
  end

  describe 'payload validation methods' do
    describe '.validate_payload' do
      it 'validates Generic Template format' do
        valid_payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Card Title',
              'buttons' => [
                {
                  'type' => 'postback',
                  'title' => 'Select',
                  'payload' => 'select_card'
                }
              ]
            }
          ]
        }

        result = described_class.send(:validate_payload, 'GENERIC_TEMPLATE', valid_payload)
        expect(result).to be true
      end

      it 'validates Button Template format' do
        valid_payload = {
          'template_type' => 'button',
          'text' => 'Choose an option:',
          'buttons' => [
            {
              'type' => 'postback',
              'title' => 'Option 1',
              'payload' => 'option_1'
            }
          ]
        }

        result = described_class.send(:validate_payload, 'BUTTON_TEMPLATE', valid_payload)
        expect(result).to be true
      end

      it 'validates Quick Replies format' do
        valid_payload = {
          'text' => 'Select an option:',
          'quick_replies' => [
            {
              'content_type' => 'text',
              'title' => 'Option 1',
              'payload' => 'option_1'
            }
          ]
        }

        result = described_class.send(:validate_payload, 'QUICK_REPLIES', valid_payload)
        expect(result).to be true
      end

      it 'rejects non-Hash payloads' do
        result = described_class.send(:validate_payload, 'BUTTON_TEMPLATE', 'invalid_payload')
        expect(result).to be false
      end

      it 'rejects unknown message formats' do
        valid_payload = { 'some_data' => 'test' }
        result = described_class.send(:validate_payload, 'UNKNOWN_FORMAT', valid_payload)
        expect(result).to be false
      end

      it 'logs validation details' do
        allow(Rails.logger).to receive(:info)
        valid_payload = {
          'template_type' => 'button',
          'text' => 'Choose an option:',
          'buttons' => [
            {
              'type' => 'postback',
              'title' => 'Option 1',
              'payload' => 'option_1'
            }
          ]
        }

        described_class.send(:validate_payload, 'BUTTON_TEMPLATE', valid_payload)

        expect(Rails.logger).to have_received(:info).with(match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*STARTING PAYLOAD VALIDATION/))
        expect(Rails.logger).to have_received(:info).with(match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*PAYLOAD VALIDATION SUCCESSFUL/))
      end
    end

    describe '.validate_generic_template' do
      it 'validates valid Generic Template payload' do
        valid_payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Card Title',
              'subtitle' => 'Card Subtitle',
              'image_url' => 'https://example.com/image.jpg',
              'buttons' => [
                {
                  'type' => 'postback',
                  'title' => 'Select',
                  'payload' => 'select_card'
                }
              ]
            }
          ]
        }

        result = described_class.send(:validate_generic_template, valid_payload)
        expect(result).to be true
      end

      it 'rejects Generic Template with wrong template_type' do
        invalid_payload = {
          'template_type' => 'button',
          'elements' => [
            {
              'title' => 'Card Title'
            }
          ]
        }

        result = described_class.send(:validate_generic_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Generic Template with missing elements' do
        invalid_payload = {
          'template_type' => 'generic'
        }

        result = described_class.send(:validate_generic_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Generic Template with empty elements array' do
        invalid_payload = {
          'template_type' => 'generic',
          'elements' => []
        }

        result = described_class.send(:validate_generic_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Generic Template with too many elements' do
        elements = (1..11).map do |i|
          {
            'title' => "Card #{i}"
          }
        end

        invalid_payload = {
          'template_type' => 'generic',
          'elements' => elements
        }

        result = described_class.send(:validate_generic_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Generic Template with element missing title' do
        invalid_payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'subtitle' => 'Card Subtitle'
            }
          ]
        }

        result = described_class.send(:validate_generic_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Generic Template with title too long' do
        invalid_payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'a' * 81 # Exceeds 80 character limit
            }
          ]
        }

        result = described_class.send(:validate_generic_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Generic Template with subtitle too long' do
        invalid_payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Card Title',
              'subtitle' => 'a' * 81 # Exceeds 80 character limit
            }
          ]
        }

        result = described_class.send(:validate_generic_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Generic Template with invalid image URL' do
        invalid_payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Card Title',
              'image_url' => 'invalid_url'
            }
          ]
        }

        result = described_class.send(:validate_generic_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Generic Template with too many buttons per element' do
        invalid_payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Card Title',
              'buttons' => [
                { 'type' => 'postback', 'title' => 'Button 1', 'payload' => 'btn1' },
                { 'type' => 'postback', 'title' => 'Button 2', 'payload' => 'btn2' },
                { 'type' => 'postback', 'title' => 'Button 3', 'payload' => 'btn3' },
                { 'type' => 'postback', 'title' => 'Button 4', 'payload' => 'btn4' } # Too many
              ]
            }
          ]
        }

        result = described_class.send(:validate_generic_template, invalid_payload)
        expect(result).to be false
      end
    end

    describe '.validate_button_template' do
      it 'validates valid Button Template payload' do
        valid_payload = {
          'template_type' => 'button',
          'text' => 'Choose an option:',
          'buttons' => [
            {
              'type' => 'postback',
              'title' => 'Option 1',
              'payload' => 'option_1'
            }
          ]
        }

        result = described_class.send(:validate_button_template, valid_payload)
        expect(result).to be true
      end

      it 'rejects Button Template with wrong template_type' do
        invalid_payload = {
          'template_type' => 'generic',
          'text' => 'Choose an option:',
          'buttons' => [
            {
              'type' => 'postback',
              'title' => 'Option 1',
              'payload' => 'option_1'
            }
          ]
        }

        result = described_class.send(:validate_button_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Button Template with missing text' do
        invalid_payload = {
          'template_type' => 'button',
          'buttons' => [
            {
              'type' => 'postback',
              'title' => 'Option 1',
              'payload' => 'option_1'
            }
          ]
        }

        result = described_class.send(:validate_button_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Button Template with text too long' do
        invalid_payload = {
          'template_type' => 'button',
          'text' => 'a' * 2001, # Exceeds 2000 character limit
          'buttons' => [
            {
              'type' => 'postback',
              'title' => 'Option 1',
              'payload' => 'option_1'
            }
          ]
        }

        result = described_class.send(:validate_button_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Button Template with missing buttons' do
        invalid_payload = {
          'template_type' => 'button',
          'text' => 'Choose an option:'
        }

        result = described_class.send(:validate_button_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Button Template with empty buttons array' do
        invalid_payload = {
          'template_type' => 'button',
          'text' => 'Choose an option:',
          'buttons' => []
        }

        result = described_class.send(:validate_button_template, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Button Template with too many buttons' do
        invalid_payload = {
          'template_type' => 'button',
          'text' => 'Choose an option:',
          'buttons' => [
            { 'type' => 'postback', 'title' => 'Option 1', 'payload' => 'option_1' },
            { 'type' => 'postback', 'title' => 'Option 2', 'payload' => 'option_2' },
            { 'type' => 'postback', 'title' => 'Option 3', 'payload' => 'option_3' },
            { 'type' => 'postback', 'title' => 'Option 4', 'payload' => 'option_4' } # Too many
          ]
        }

        result = described_class.send(:validate_button_template, invalid_payload)
        expect(result).to be false
      end
    end

    describe '.validate_quick_replies' do
      it 'validates valid Quick Replies payload' do
        valid_payload = {
          'text' => 'Select an option:',
          'quick_replies' => [
            {
              'content_type' => 'text',
              'title' => 'Option 1',
              'payload' => 'option_1'
            },
            {
              'content_type' => 'text',
              'title' => 'Option 2',
              'payload' => 'option_2'
            }
          ]
        }

        result = described_class.send(:validate_quick_replies, valid_payload)
        expect(result).to be true
      end

      it 'rejects Quick Replies with missing text' do
        invalid_payload = {
          'quick_replies' => [
            {
              'content_type' => 'text',
              'title' => 'Option 1',
              'payload' => 'option_1'
            }
          ]
        }

        result = described_class.send(:validate_quick_replies, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Quick Replies with text too long' do
        invalid_payload = {
          'text' => 'a' * 2001, # Exceeds 2000 character limit
          'quick_replies' => [
            {
              'content_type' => 'text',
              'title' => 'Option 1',
              'payload' => 'option_1'
            }
          ]
        }

        result = described_class.send(:validate_quick_replies, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Quick Replies with missing quick_replies' do
        invalid_payload = {
          'text' => 'Select an option:'
        }

        result = described_class.send(:validate_quick_replies, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Quick Replies with empty quick_replies array' do
        invalid_payload = {
          'text' => 'Select an option:',
          'quick_replies' => []
        }

        result = described_class.send(:validate_quick_replies, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Quick Replies with too many quick replies' do
        quick_replies = (1..14).map do |i|
          {
            'content_type' => 'text',
            'title' => "Option #{i}",
            'payload' => "option_#{i}"
          }
        end

        invalid_payload = {
          'text' => 'Select an option:',
          'quick_replies' => quick_replies
        }

        result = described_class.send(:validate_quick_replies, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Quick Replies with invalid content_type' do
        invalid_payload = {
          'text' => 'Select an option:',
          'quick_replies' => [
            {
              'content_type' => 'image',
              'title' => 'Option 1',
              'payload' => 'option_1'
            }
          ]
        }

        result = described_class.send(:validate_quick_replies, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Quick Replies with missing title' do
        invalid_payload = {
          'text' => 'Select an option:',
          'quick_replies' => [
            {
              'content_type' => 'text',
              'payload' => 'option_1'
            }
          ]
        }

        result = described_class.send(:validate_quick_replies, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Quick Replies with title too long' do
        invalid_payload = {
          'text' => 'Select an option:',
          'quick_replies' => [
            {
              'content_type' => 'text',
              'title' => 'a' * 21, # Exceeds 20 character limit
              'payload' => 'option_1'
            }
          ]
        }

        result = described_class.send(:validate_quick_replies, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Quick Replies with missing payload' do
        invalid_payload = {
          'text' => 'Select an option:',
          'quick_replies' => [
            {
              'content_type' => 'text',
              'title' => 'Option 1'
            }
          ]
        }

        result = described_class.send(:validate_quick_replies, invalid_payload)
        expect(result).to be false
      end

      it 'rejects Quick Replies with payload too long' do
        invalid_payload = {
          'text' => 'Select an option:',
          'quick_replies' => [
            {
              'content_type' => 'text',
              'title' => 'Option 1',
              'payload' => 'a' * 1001 # Exceeds 1000 character limit
            }
          ]
        }

        result = described_class.send(:validate_quick_replies, invalid_payload)
        expect(result).to be false
      end
    end

    describe '.validate_button' do
      it 'validates valid postback button' do
        valid_button = {
          'type' => 'postback',
          'title' => 'Select',
          'payload' => 'select_option'
        }

        result = described_class.send(:validate_button, valid_button, 'Test Button')
        expect(result).to be true
      end

      it 'validates valid web_url button' do
        valid_button = {
          'type' => 'web_url',
          'title' => 'Visit',
          'url' => 'https://example.com'
        }

        result = described_class.send(:validate_button, valid_button, 'Test Button')
        expect(result).to be true
      end

      it 'rejects non-Hash button' do
        result = described_class.send(:validate_button, 'invalid_button', 'Test Button')
        expect(result).to be false
      end

      it 'rejects button with missing type' do
        invalid_button = {
          'title' => 'Select',
          'payload' => 'select_option'
        }

        result = described_class.send(:validate_button, invalid_button, 'Test Button')
        expect(result).to be false
      end

      it 'rejects button with missing title' do
        invalid_button = {
          'type' => 'postback',
          'payload' => 'select_option'
        }

        result = described_class.send(:validate_button, invalid_button, 'Test Button')
        expect(result).to be false
      end

      it 'rejects button with title too long' do
        invalid_button = {
          'type' => 'postback',
          'title' => 'a' * 21, # Exceeds 20 character limit
          'payload' => 'select_option'
        }

        result = described_class.send(:validate_button, invalid_button, 'Test Button')
        expect(result).to be false
      end

      it 'rejects postback button with missing payload' do
        invalid_button = {
          'type' => 'postback',
          'title' => 'Select'
        }

        result = described_class.send(:validate_button, invalid_button, 'Test Button')
        expect(result).to be false
      end

      it 'rejects postback button with payload too long' do
        invalid_button = {
          'type' => 'postback',
          'title' => 'Select',
          'payload' => 'a' * 1001 # Exceeds 1000 character limit
        }

        result = described_class.send(:validate_button, invalid_button, 'Test Button')
        expect(result).to be false
      end

      it 'rejects web_url button with missing url' do
        invalid_button = {
          'type' => 'web_url',
          'title' => 'Visit'
        }

        result = described_class.send(:validate_button, invalid_button, 'Test Button')
        expect(result).to be false
      end

      it 'rejects web_url button with invalid url' do
        invalid_button = {
          'type' => 'web_url',
          'title' => 'Visit',
          'url' => 'invalid_url'
        }

        result = described_class.send(:validate_button, invalid_button, 'Test Button')
        expect(result).to be false
      end

      it 'rejects button with invalid type' do
        invalid_button = {
          'type' => 'invalid_type',
          'title' => 'Select',
          'payload' => 'select_option'
        }

        result = described_class.send(:validate_button, invalid_button, 'Test Button')
        expect(result).to be false
      end
    end

    describe '.validate_web_url' do
      it 'validates valid HTTP URL' do
        result = described_class.send(:validate_web_url, 'http://example.com', 'Test URL')
        expect(result).to be true
      end

      it 'validates valid HTTPS URL' do
        result = described_class.send(:validate_web_url, 'https://example.com', 'Test URL')
        expect(result).to be true
      end

      it 'rejects URL with invalid format' do
        result = described_class.send(:validate_web_url, 'invalid_url', 'Test URL')
        expect(result).to be false
      end

      it 'rejects URL with unsupported scheme' do
        result = described_class.send(:validate_web_url, 'ftp://example.com', 'Test URL')
        expect(result).to be false
      end

      it 'rejects URL without host' do
        result = described_class.send(:validate_web_url, 'https://', 'Test URL')
        expect(result).to be false
      end

      it 'rejects URL that is too long' do
        long_url = 'https://example.com/' + 'a' * 2000
        result = described_class.send(:validate_web_url, long_url, 'Test URL')
        expect(result).to be false
      end

      it 'handles malformed URLs gracefully' do
        result = described_class.send(:validate_web_url, 'https://[invalid', 'Test URL')
        expect(result).to be false
      end
    end

    describe '.validate_image_url' do
      it 'validates valid image URL with jpg extension' do
        result = described_class.send(:validate_image_url, 'https://example.com/image.jpg', 'Test Image')
        expect(result).to be true
      end

      it 'validates valid image URL with png extension' do
        result = described_class.send(:validate_image_url, 'https://example.com/image.png', 'Test Image')
        expect(result).to be true
      end

      it 'validates valid image URL with gif extension' do
        result = described_class.send(:validate_image_url, 'https://example.com/image.gif', 'Test Image')
        expect(result).to be true
      end

      it 'validates URL without image extension (with warning)' do
        allow(Rails.logger).to receive(:warn)
        result = described_class.send(:validate_image_url, 'https://example.com/image', 'Test Image')
        expect(result).to be true
        expect(Rails.logger).to have_received(:warn).with(match(/may not be a valid image URL/))
      end

      it 'rejects invalid URL format' do
        result = described_class.send(:validate_image_url, 'invalid_url', 'Test Image')
        expect(result).to be false
      end
    end
  end

  describe 'fallback behavior' do
    describe '.fallback_to_text_message' do
      it 'creates text message with extracted content' do
        socialwise_data = {
          'payload' => {
            'text' => 'Fallback text content'
          }
        }

        expect(conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Fallback text content',
            message_type: :outgoing,
            account_id: conversation.account_id,
            inbox_id: conversation.inbox_id
          )
        )

        described_class.send(:fallback_to_text_message, message, socialwise_data)
      end

      it 'creates generic message when no text can be extracted' do
        socialwise_data = {}

        expect(conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Message received',
            message_type: :outgoing
          )
        )

        described_class.send(:fallback_to_text_message, message, socialwise_data)
      end

      it 'logs fallback operation' do
        allow(Rails.logger).to receive(:info)
        allow(conversation.messages).to receive(:create!)

        described_class.send(:fallback_to_text_message, message, {})

        expect(Rails.logger).to have_received(:info).with(match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*Falling back to text message/))
      end
    end

    describe '.extract_fallback_text' do
      it 'extracts text from Button Template payload' do
        socialwise_data = {
          'payload' => {
            'text' => 'Button template text'
          }
        }

        result = described_class.send(:extract_fallback_text, socialwise_data)
        expect(result).to eq('Button template text')
      end

      it 'extracts text from Quick Replies payload' do
        socialwise_data = {
          'payload' => {
            'text' => 'Quick replies text'
          }
        }

        result = described_class.send(:extract_fallback_text, socialwise_data)
        expect(result).to eq('Quick replies text')
      end

      it 'extracts title from Generic Template payload' do
        socialwise_data = {
          'payload' => {
            'elements' => [
              {
                'title' => 'First card title'
              }
            ]
          }
        }

        result = described_class.send(:extract_fallback_text, socialwise_data)
        expect(result).to eq('First card title')
      end

      it 'returns generic message when no text can be extracted' do
        socialwise_data = {}

        result = described_class.send(:extract_fallback_text, socialwise_data)
        expect(result).to eq('Message received')
      end

      it 'handles malformed payload gracefully' do
        socialwise_data = {
          'payload' => 'invalid_payload'
        }

        result = described_class.send(:extract_fallback_text, socialwise_data)
        expect(result).to eq('Message received')
      end
    end
  end
end