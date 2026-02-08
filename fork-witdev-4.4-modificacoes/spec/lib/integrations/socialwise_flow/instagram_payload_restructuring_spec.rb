# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SocialWise Flow Instagram Payload Restructuring Fix' do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }

  let(:socialwise_hook) do
    create(:integrations_hook, 
           app_id: 'socialwise_flow',
           account: account,
           inbox: inbox,
           settings: {
             'endpoint' => 'https://socialwise.witdev.com.br/api/integrations/webhooks/socialwiseflow',
             'access_token' => 'test_token'
           })
  end

  let(:processor_service) do
    Integrations::SocialwiseFlow::ProcessorService.new(
      event_name: 'message.created',
      hook: socialwise_hook,
      event_data: { message: message }
    )
  end

  describe 'Instagram payload restructuring fix' do
    context 'when processing GENERIC_TEMPLATE' do
      let(:socialwise_response) do
        {
          'instagram' => {
            'message_format' => 'GENERIC_TEMPLATE',
            'template_type' => 'generic',
            'elements' => [
              {
                'title' => 'mandado de segurança',
                'buttons' => [
                  {
                    'type' => 'postback',
                    'title' => 'atendimento',
                    'payload' => 'ig_btn_test'
                  }
                ]
              }
            ]
          }
        }
      end

      it 'restructures SocialWise Flow payload to InstagramResponseProcessor format' do
        # Mock the InstagramResponseProcessor to capture the restructured payload
        restructured_payload = nil
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process) do |payload, msg|
          restructured_payload = payload
          true
        end

        # Process the response
        processor_service.send(:process_response, message, socialwise_response)

        # Verify the payload was restructured correctly
        expect(restructured_payload).to be_present
        expect(restructured_payload['message_format']).to eq('GENERIC_TEMPLATE')
        expect(restructured_payload['payload']).to be_present
        expect(restructured_payload['payload']['template_type']).to eq('generic')
        expect(restructured_payload['payload']['elements']).to be_present
        expect(restructured_payload['payload']['elements'].first['title']).to eq('mandado de segurança')
      end

      it 'removes message_format from payload section' do
        restructured_payload = nil
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process) do |payload, msg|
          restructured_payload = payload
          true
        end

        processor_service.send(:process_response, message, socialwise_response)

        # Verify message_format is not duplicated in payload
        expect(restructured_payload['payload']).not_to have_key('message_format')
        expect(restructured_payload['payload']['template_type']).to eq('generic')
      end
    end

    context 'when processing BUTTON_TEMPLATE' do
      let(:socialwise_response) do
        {
          'instagram' => {
            'message_format' => 'BUTTON_TEMPLATE',
            'template_type' => 'button',
            'text' => 'Button template text',
            'buttons' => [
              {
                'type' => 'postback',
                'title' => 'Test Button',
                'payload' => 'test_payload'
              }
            ]
          }
        }
      end

      it 'restructures Button Template payload correctly' do
        restructured_payload = nil
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process) do |payload, msg|
          restructured_payload = payload
          true
        end

        processor_service.send(:process_response, message, socialwise_response)

        expect(restructured_payload['message_format']).to eq('BUTTON_TEMPLATE')
        expect(restructured_payload['payload']['template_type']).to eq('button')
        expect(restructured_payload['payload']['text']).to eq('Button template text')
        expect(restructured_payload['payload']['buttons']).to be_present
        expect(restructured_payload['payload']).not_to have_key('message_format')
      end
    end

    context 'when processing QUICK_REPLIES' do
      let(:socialwise_response) do
        {
          'instagram' => {
            'message_format' => 'QUICK_REPLIES',
            'text' => 'Quick replies text',
            'quick_replies' => [
              {
                'content_type' => 'text',
                'title' => 'Option 1',
                'payload' => 'option_1'
              }
            ]
          }
        }
      end

      it 'restructures Quick Replies payload correctly' do
        restructured_payload = nil
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process) do |payload, msg|
          restructured_payload = payload
          true
        end

        processor_service.send(:process_response, message, socialwise_response)

        expect(restructured_payload['message_format']).to eq('QUICK_REPLIES')
        expect(restructured_payload['payload']['text']).to eq('Quick replies text')
        expect(restructured_payload['payload']['quick_replies']).to be_present
        expect(restructured_payload['payload']).not_to have_key('message_format')
      end
    end

    context 'when InstagramResponseProcessor fails' do
      let(:socialwise_response) do
        {
          'instagram' => {
            'message_format' => 'GENERIC_TEMPLATE',
            'template_type' => 'generic',
            'elements' => []
          }
        }
      end

      it 'creates fallback message when processor returns false' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
        
        initial_message_count = conversation.messages.count
        
        processor_service.send(:process_response, message, socialwise_response)
        
        # Should create a fallback message
        expect(conversation.messages.count).to eq(initial_message_count + 1)
        fallback_message = conversation.messages.last
        expect(fallback_message.content).to be_present
        expect(fallback_message.message_type).to eq('outgoing')
      end

      it 'creates fallback message when processor raises exception' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_raise(StandardError, 'Test error')
        
        initial_message_count = conversation.messages.count
        
        processor_service.send(:process_response, message, socialwise_response)
        
        # Should create a fallback message
        expect(conversation.messages.count).to eq(initial_message_count + 1)
        fallback_message = conversation.messages.last
        expect(fallback_message.content).to be_present
        expect(fallback_message.message_type).to eq('outgoing')
      end
    end

    context 'compatibility with Dialogflow format' do
      it 'produces same structure as Dialogflow socialwiseResponse' do
        # Simulate Dialogflow format
        dialogflow_format = {
          'message_format' => 'GENERIC_TEMPLATE',
          'payload' => {
            'template_type' => 'generic',
            'elements' => [
              {
                'title' => 'Test Title',
                'buttons' => [
                  {
                    'type' => 'postback',
                    'title' => 'Test Button',
                    'payload' => 'test'
                  }
                ]
              }
            ]
          }
        }

        # SocialWise Flow format
        socialwise_format = {
          'instagram' => {
            'message_format' => 'GENERIC_TEMPLATE',
            'template_type' => 'generic',
            'elements' => [
              {
                'title' => 'Test Title',
                'buttons' => [
                  {
                    'type' => 'postback',
                    'title' => 'Test Button',
                    'payload' => 'test'
                  }
                ]
              }
            ]
          }
        }

        restructured_payload = nil
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process) do |payload, msg|
          restructured_payload = payload
          true
        end

        processor_service.send(:process_response, message, socialwise_format)

        # Verify the restructured payload matches Dialogflow format
        expect(restructured_payload.keys).to match_array(dialogflow_format.keys)
        expect(restructured_payload['message_format']).to eq(dialogflow_format['message_format'])
        expect(restructured_payload['payload'].keys).to match_array(dialogflow_format['payload'].keys)
        expect(restructured_payload['payload']['template_type']).to eq(dialogflow_format['payload']['template_type'])
      end
    end
  end
end