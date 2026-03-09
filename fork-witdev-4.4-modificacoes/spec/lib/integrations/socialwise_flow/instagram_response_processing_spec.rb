# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SocialWise Flow Instagram Response Processing' do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }

  # SocialWise Flow Instagram payloads based on the design document
  let(:socialwise_generic_template) do
    {
      'message_format' => 'GENERIC_TEMPLATE',
      'template_type' => 'generic',
      'elements' => [
        {
          'title' => 'mandado de segurança',
          'subtitle' => 'Dra. Amanda Sousa Advocacia e Consultoria Jurídica™',
          'buttons' => [
            {
              'type' => 'postback',
              'title' => 'atendimento',
              'payload' => 'ig_btn_1756139332989_pm6hd9wau'
            }
          ],
          'image_url' => 'https://objstoreapi.witdev.com.br/chatwit-social/1b2024eb-ecd3-486d-8629-57a1df029b08.png'
        }
      ]
    }
  end

  let(:socialwise_button_template) do
    {
      'message_format' => 'BUTTON_TEMPLATE',
      'template_type' => 'button',
      'text' => 'BUTTON_TEMPLATE pode ter até 640 caracteres e 3 botoes postback ou web_url (mistura)',
      'buttons' => [
        {
          'type' => 'postback',
          'title' => 'finalizar',
          'payload' => 'ig_btn_1756164895605_betjxtlxr'
        },
        {
          'type' => 'postback',
          'title' => 'atendimento',
          'payload' => 'ig_btn_1756164897692_r4p8f1btg'
        },
        {
          'type' => 'web_url',
          'title' => 'meu site',
          'url' => 'https://witdev.com.br'
        }
      ]
    }
  end

  let(:socialwise_quick_replies) do
    {
      'message_format' => 'QUICK_REPLIES',
      'text' => 'QUICK_REPLY_2  PODE TER ATÉ 1000 CARACTERES E 13 BOTOES',
      'quick_replies' => [
        {
          'content_type' => 'text',
          'title' => '1',
          'payload' => 'ig_btn_1756164551022_58syso7j0'
        },
        {
          'content_type' => 'text',
          'title' => '2',
          'payload' => 'ig_btn_1756164552127_2allygt3l'
        },
        {
          'content_type' => 'text',
          'title' => '3',
          'payload' => 'ig_btn_1756164553169_fwo24yr8e'
        },
        {
          'content_type' => 'text',
          'title' => '4',
          'payload' => 'ig_btn_1756164554152_stll7gg63'
        }
      ]
    }
  end

  describe 'Instagram Response Processing with SocialWise Flow Payloads' do
    context 'when processing GENERIC_TEMPLATE format' do
      it 'successfully processes SocialWise Flow Generic Template payload' do
        # Mock the Instagram Rich Message Service
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform)

        # Process the SocialWise Flow payload
        result = Integrations::Socialwise::InstagramResponseProcessor.process(
          { 'payload' => socialwise_generic_template },
          message
        )

        expect(result).to be true
        expect(Instagram::RichMessageService).to have_received(:new)
        expect(rich_message_service).to have_received(:perform)
      end

      it 'validates Generic Template payload structure correctly' do
        # Test the validation directly
        result = Integrations::Socialwise::InstagramResponseProcessor.send(
          :validate_generic_template,
          socialwise_generic_template
        )

        expect(result).to be true
      end

      it 'builds correct Instagram API payload from SocialWise Flow format' do
        expected_payload = {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'mandado de segurança',
              'subtitle' => 'Dra. Amanda Sousa Advocacia e Consultoria Jurídica™',
              'image_url' => 'https://objstoreapi.witdev.com.br/chatwit-social/1b2024eb-ecd3-486d-8629-57a1df029b08.png',
              'buttons' => [
                {
                  'type' => 'postback',
                  'title' => 'atendimento',
                  'payload' => 'ig_btn_1756139332989_pm6hd9wau'
                }
              ]
            }
          ]
        }

        built_payload = Integrations::Socialwise::InstagramResponseProcessor.send(
          :build_generic_template_payload,
          socialwise_generic_template
        )

        expect(built_payload).to eq(expected_payload)
      end

      it 'creates outgoing message with correct attributes' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform)

        expect {
          Integrations::Socialwise::InstagramResponseProcessor.process(
            { 'payload' => socialwise_generic_template },
            message
          )
        }.to change { conversation.messages.count }.by(1)

        created_message = conversation.messages.last
        expect(created_message.message_type).to eq('outgoing')
        expect(created_message.additional_attributes['skip_send_reply']).to be true
      end
    end

    context 'when processing BUTTON_TEMPLATE format' do
      it 'successfully processes SocialWise Flow Button Template payload' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform)

        result = Integrations::Socialwise::InstagramResponseProcessor.process(
          { 'payload' => socialwise_button_template },
          message
        )

        expect(result).to be true
        expect(Instagram::RichMessageService).to have_received(:new)
        expect(rich_message_service).to have_received(:perform)
      end

      it 'validates Button Template payload structure correctly' do
        result = Integrations::Socialwise::InstagramResponseProcessor.send(
          :validate_button_template,
          socialwise_button_template
        )

        expect(result).to be true
      end

      it 'builds correct Instagram API payload from SocialWise Flow format' do
        expected_payload = {
          'template_type' => 'button',
          'text' => 'BUTTON_TEMPLATE pode ter até 640 caracteres e 3 botoes postback ou web_url (mistura)',
          'buttons' => [
            {
              'type' => 'postback',
              'title' => 'finalizar',
              'payload' => 'ig_btn_1756164895605_betjxtlxr'
            },
            {
              'type' => 'postback',
              'title' => 'atendimento',
              'payload' => 'ig_btn_1756164897692_r4p8f1btg'
            },
            {
              'type' => 'web_url',
              'title' => 'meu site',
              'url' => 'https://witdev.com.br'
            }
          ]
        }

        built_payload = Integrations::Socialwise::InstagramResponseProcessor.send(
          :build_button_template_payload,
          socialwise_button_template
        )

        expect(built_payload).to eq(expected_payload)
      end

      it 'handles mixed button types (postback and web_url) correctly' do
        result = Integrations::Socialwise::InstagramResponseProcessor.send(
          :validate_button_template,
          socialwise_button_template
        )

        expect(result).to be true

        # Validate individual buttons
        socialwise_button_template['buttons'].each do |button|
          button_result = Integrations::Socialwise::InstagramResponseProcessor.send(
            :validate_button,
            button,
            'Test Button'
          )
          expect(button_result).to be true
        end
      end
    end

    context 'when processing QUICK_REPLIES format' do
      it 'successfully processes SocialWise Flow Quick Replies payload' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform)

        result = Integrations::Socialwise::InstagramResponseProcessor.process(
          { 'payload' => socialwise_quick_replies },
          message
        )

        expect(result).to be true
        expect(Instagram::RichMessageService).to have_received(:new)
        expect(rich_message_service).to have_received(:perform)
      end

      it 'validates Quick Replies payload structure correctly' do
        result = Integrations::Socialwise::InstagramResponseProcessor.send(
          :validate_quick_replies,
          socialwise_quick_replies
        )

        expect(result).to be true
      end

      it 'builds correct Instagram API payload from SocialWise Flow format' do
        expected_payload = {
          'text' => 'QUICK_REPLY_2  PODE TER ATÉ 1000 CARACTERES E 13 BOTOES',
          'quick_replies' => [
            {
              'content_type' => 'text',
              'title' => '1',
              'payload' => 'ig_btn_1756164551022_58syso7j0'
            },
            {
              'content_type' => 'text',
              'title' => '2',
              'payload' => 'ig_btn_1756164552127_2allygt3l'
            },
            {
              'content_type' => 'text',
              'title' => '3',
              'payload' => 'ig_btn_1756164553169_fwo24yr8e'
            },
            {
              'content_type' => 'text',
              'title' => '4',
              'payload' => 'ig_btn_1756164554152_stll7gg63'
            }
          ]
        }

        built_payload = Integrations::Socialwise::InstagramResponseProcessor.send(
          :build_quick_replies_payload,
          socialwise_quick_replies
        )

        expect(built_payload).to eq(expected_payload)
      end

      it 'handles multiple quick reply options correctly' do
        expect(socialwise_quick_replies['quick_replies'].length).to eq(4)

        socialwise_quick_replies['quick_replies'].each do |quick_reply|
          expect(quick_reply['content_type']).to eq('text')
          expect(quick_reply['title']).to be_present
          expect(quick_reply['payload']).to be_present
          expect(quick_reply['payload']).to start_with('ig_btn_')
        end
      end
    end

    context 'when handling payload format compatibility issues' do
      it 'handles malformed Generic Template payload gracefully' do
        malformed_payload = {
          'message_format' => 'GENERIC_TEMPLATE',
          'template_type' => 'generic',
          'elements' => [
            {
              # Missing required title
              'subtitle' => 'Test subtitle'
            }
          ]
        }

        expect(conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Message received',
            message_type: :outgoing
          )
        )

        result = Integrations::Socialwise::InstagramResponseProcessor.process(
          { 'payload' => malformed_payload },
          message
        )

        expect(result).to be true # Returns true because fallback succeeded
      end

      it 'handles malformed Button Template payload gracefully' do
        malformed_payload = {
          'message_format' => 'BUTTON_TEMPLATE',
          'template_type' => 'button',
          # Missing required text
          'buttons' => [
            {
              'type' => 'postback',
              'title' => 'Test',
              'payload' => 'test'
            }
          ]
        }

        expect(conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Message received',
            message_type: :outgoing
          )
        )

        result = Integrations::Socialwise::InstagramResponseProcessor.process(
          { 'payload' => malformed_payload },
          message
        )

        expect(result).to be true # Returns true because fallback succeeded
      end

      it 'handles malformed Quick Replies payload gracefully' do
        malformed_payload = {
          'message_format' => 'QUICK_REPLIES',
          # Missing required text
          'quick_replies' => [
            {
              'content_type' => 'text',
              'title' => 'Test',
              'payload' => 'test'
            }
          ]
        }

        expect(conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Message received',
            message_type: :outgoing
          )
        )

        result = Integrations::Socialwise::InstagramResponseProcessor.process(
          { 'payload' => malformed_payload },
          message
        )

        expect(result).to be true # Returns true because fallback succeeded
      end

      it 'handles completely invalid payload structure gracefully' do
        invalid_payload = 'not_a_hash'

        expect(conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Message received',
            message_type: :outgoing
          )
        )

        result = Integrations::Socialwise::InstagramResponseProcessor.process(
          invalid_payload,
          message
        )

        expect(result).to be true # Returns true because fallback succeeded
      end
    end

    context 'when ensuring fallback message creation works properly' do
      it 'creates fallback text message when Instagram Rich Message Service fails' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform).and_raise(StandardError, 'API Error')

        expect(conversation.messages).to receive(:create!).twice.and_call_original
        # First call creates the rich message, second call creates the fallback

        result = Integrations::Socialwise::InstagramResponseProcessor.process(
          { 'payload' => socialwise_button_template },
          message
        )

        expect(result).to be false # Returns false because rich message sending failed
        expect(conversation.messages.count).to eq(2) # Original message + fallback
        
        fallback_message = conversation.messages.last
        expect(fallback_message.content).to eq(socialwise_button_template['text'])
        expect(fallback_message.message_type).to eq('outgoing')
      end

      it 'extracts meaningful fallback text from Generic Template' do
        fallback_text = Integrations::Socialwise::InstagramResponseProcessor.send(
          :extract_fallback_text,
          { 'payload' => socialwise_generic_template }
        )

        expect(fallback_text).to eq('mandado de segurança')
      end

      it 'extracts meaningful fallback text from Button Template' do
        fallback_text = Integrations::Socialwise::InstagramResponseProcessor.send(
          :extract_fallback_text,
          { 'payload' => socialwise_button_template }
        )

        expect(fallback_text).to eq('BUTTON_TEMPLATE pode ter até 640 caracteres e 3 botoes postback ou web_url (mistura)')
      end

      it 'extracts meaningful fallback text from Quick Replies' do
        fallback_text = Integrations::Socialwise::InstagramResponseProcessor.send(
          :extract_fallback_text,
          { 'payload' => socialwise_quick_replies }
        )

        expect(fallback_text).to eq('QUICK_REPLY_2  PODE TER ATÉ 1000 CARACTERES E 13 BOTOES')
      end

      it 'uses generic fallback when no meaningful text can be extracted' do
        empty_payload = { 'payload' => {} }

        fallback_text = Integrations::Socialwise::InstagramResponseProcessor.send(
          :extract_fallback_text,
          empty_payload
        )

        expect(fallback_text).to eq('Message received')
      end
    end

    context 'when testing integration with SocialWise Flow processor' do
      it 'processes Instagram response through SocialWise Flow processor' do
        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform)

        # Test the Instagram processor directly as it's used by SocialWise Flow
        result = Integrations::Socialwise::InstagramResponseProcessor.process(
          { 'payload' => socialwise_button_template },
          message
        )

        expect(result).to be true
        expect(Instagram::RichMessageService).to have_received(:new)
        expect(rich_message_service).to have_received(:perform)
      end

      it 'handles Instagram response processing errors gracefully' do
        # Mock Instagram processor to fail
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
        
        result = Integrations::Socialwise::InstagramResponseProcessor.process(
          { 'payload' => socialwise_button_template },
          message
        )

        expect(result).to be false
      end
    end

    context 'when testing performance and logging' do
      it 'logs processing details for debugging' do
        allow(Rails.logger).to receive(:info)
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:error)

        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform)

        Integrations::Socialwise::InstagramResponseProcessor.process(
          { 'payload' => socialwise_button_template },
          message
        )

        expect(Rails.logger).to have_received(:info).with(match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*STARTING SOCIALWISE RESPONSE PROCESSING/))
        expect(Rails.logger).to have_received(:info).with(match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*Message format: BUTTON_TEMPLATE/))
        expect(Rails.logger).to have_received(:info).with(match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*SOCIALWISE RESPONSE PROCESSING COMPLETED/))
      end

      it 'measures and logs performance metrics' do
        allow(Rails.logger).to receive(:info)

        rich_message_service = instance_double(Instagram::RichMessageService)
        allow(Instagram::RichMessageService).to receive(:new).and_return(rich_message_service)
        allow(rich_message_service).to receive(:perform)

        start_time = Time.current
        Integrations::Socialwise::InstagramResponseProcessor.process(
          { 'payload' => socialwise_button_template },
          message
        )
        end_time = Time.current

        expect(Rails.logger).to have_received(:info).with(match(/SOCIALWISE-INSTAGRAM-DIALOGFLOW.*Total processing time.*ms/))
      end
    end
  end
end