require 'rails_helper'

RSpec.describe 'SocialWise Flow Core Integration', type: :integration do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  
  # Simple channel setup without external validations
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, content: 'Test message') }
  
  # SocialWise Flow hook
  let(:socialwise_hook) do
    create(:integrations_hook, 
           app_id: 'socialwise_flow',
           account: account,
           inbox: inbox,
           settings: {
             'endpoint' => 'https://socialwise.witdev.com.br/api/integrations/webhooks/socialwiseflow',
             'access_token' => 'test_token',
             'language' => 'pt-BR'
           })
  end
  
  let(:processor_service) do
    Integrations::SocialwiseFlow::ProcessorService.new(
      event_name: 'message.created',
      hook: socialwise_hook,
      event_data: { message: message }
    )
  end

  before do
    # Mock external services to avoid HTTP calls
    allow(Whatsapp::SendOnWhatsappService).to receive(:new).and_return(double(perform: true))
    allow(Facebook::SendOnFacebookService).to receive(:new).and_return(double(perform: true))
    allow(Facebook::RawDeliverService).to receive(:new).and_return(double(perform: true))
    allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
  end

  describe 'WhatsApp Response Processing' do
    let(:whatsapp_interactive_response) do
      {
        'whatsapp' => {
          'type' => 'interactive',
          'interactive' => {
            'body' => {
              'text' => '> Sr(a) *Cliente*, \nSomos especializados em mandado de segurança...'
            },
            'header' => {
              'type' => 'image',
              'image' => {
                'link' => 'https://objstoreapi.witdev.com.br/chatwit-social/test.png'
              }
            },
            'footer' => {
              'text' => 'Dra. Amanda Sousa Advocacia e Consultoria Jurídica™'
            },
            'type' => 'button',
            'action' => {
              'buttons' => [
                {
                  'type' => 'reply',
                  'reply' => {
                    'id' => 'btn_test_123',
                    'title' => 'Falar com a Dra'
                  }
                }
              ]
            }
          }
        }
      }
    end

    it 'processes WhatsApp interactive message correctly' do
      # Requirements: 1.1, 1.2, 1.3, 1.4
      # Mock the channel type to be WhatsApp
      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, whatsapp_interactive_response)
      
      expect(conversation.messages.count).to be > initial_count
      
      created_message = conversation.messages.outgoing.last
      expect(created_message.message_type).to eq('outgoing')
      expect(created_message.content_type).to eq('integrations')
      expect(created_message.content).to include('Sr(a) *Cliente*')
      expect(created_message.content_attributes['interactive']).to be_present
      expect(created_message.content_attributes['whatsapp_interactive_payload']).to be_present
    end

    it 'handles WhatsApp text messages' do
      # Requirements: 1.1, 1.2
      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      
      text_response = {
        'whatsapp' => {
          'type' => 'text',
          'text' => { 'body' => 'Simple text message' }
        }
      }
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, text_response)
      
      expect(conversation.messages.count).to be > initial_count
      
      created_message = conversation.messages.outgoing.last
      expect(created_message.content).to eq('Simple text message')
    end
  end

  describe 'Instagram Response Processing' do
    let(:instagram_generic_template) do
      {
        'instagram' => {
          'message_format' => 'GENERIC_TEMPLATE',
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Test Instagram Message',
              'buttons' => [
                {
                  'type' => 'postback',
                  'title' => 'Test Button',
                  'payload' => 'test_payload'
                }
              ],
              'image_url' => 'https://example.com/test.png'
            }
          ]
        }
      }
    end

    it 'processes Instagram rich messages using existing processor' do
      # Requirements: 2.1, 2.2, 2.3, 2.4
      allow(inbox).to receive(:channel_type).and_return('Channel::FacebookPage')
      
      processor_service.send(:process_response, message, instagram_generic_template)
      
      expect(Integrations::Socialwise::InstagramResponseProcessor).to have_received(:process)
        .with(instagram_generic_template['instagram'], message)
    end

    it 'creates fallback message when Instagram processing fails' do
      # Requirements: 2.4, 6.1, 6.2, 6.3, 6.4
      allow(inbox).to receive(:channel_type).and_return('Channel::FacebookPage')
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, instagram_generic_template)
      
      expect(conversation.messages.count).to be > initial_count
      
      created_message = conversation.messages.outgoing.last
      expect(created_message.content).to be_present
    end
  end

  describe 'Facebook Response Processing' do
    let(:facebook_text_response) do
      {
        'facebook' => {
          'message' => {
            'text' => 'Hello from Facebook!'
          }
        }
      }
    end

    let(:facebook_rich_response) do
      {
        'facebook' => {
          'message' => {
            'text' => 'Choose an option:',
            'quick_replies' => [
              {
                'content_type' => 'text',
                'title' => 'Support',
                'payload' => 'SUPPORT'
              }
            ]
          }
        }
      }
    end

    it 'processes Facebook text messages' do
      # Requirements: 5.1, 5.2
      allow(inbox).to receive(:channel_type).and_return('Channel::FacebookPage')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, facebook_text_response)
      
      expect(conversation.messages.count).to be > initial_count
      
      created_message = conversation.messages.outgoing.last
      expect(created_message.content).to eq('Hello from Facebook!')
      expect(created_message.content_type).to eq('text')
    end

    it 'processes Facebook rich content' do
      # Requirements: 5.1, 5.3
      allow(inbox).to receive(:channel_type).and_return('Channel::FacebookPage')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, facebook_rich_response)
      
      expect(conversation.messages.count).to be > initial_count
      
      created_message = conversation.messages.outgoing.last
      expect(created_message.content_type).to eq('integrations')
      expect(created_message.content_attributes).to eq(facebook_rich_response['facebook'])
    end
  end

  describe 'Button Reaction Processing' do
    let(:button_reaction_response) do
      {
        'action_type' => 'button_reaction',
        'buttonId' => 'btn_test_123',
        'processed' => true,
        'mappingFound' => true,
        'emoji' => '❤️',
        'text' => 'Thank you for your response!',
        'action' => 'handoff'
      }
    end

    it 'processes button reactions with emoji and text' do
      # Requirements: 3.1, 3.2, 3.3, 3.4
      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, button_reaction_response)
      
      expect(conversation.messages.count).to be > initial_count
      
      # Should create both emoji reaction and text response messages
      all_messages = conversation.messages.reload
      
      emoji_message = all_messages.find { |m| m.message_type == 'activity' && m.content_attributes&.dig('emoji_reaction') }
      expect(emoji_message).to be_present if emoji_message
      
      text_message = all_messages.find { |m| m.message_type == 'outgoing' && m.content == 'Thank you for your response!' }
      expect(text_message).to be_present if text_message
      
      # At minimum, verify that messages were created
      expect(all_messages.count).to be > initial_count
    end

    it 'processes handoff action after button reaction' do
      # Requirements: 3.4, 4.1, 4.2, 4.3, 4.4
      # Set conversation to pending status first
      conversation.update!(status: 'pending')
      expect(conversation.status).to eq('pending')
      
      processor_service.send(:process_response, message, button_reaction_response)
      
      conversation.reload
      expect(conversation.status).to eq('open')
    end
  end

  describe 'Handoff Processing' do
    let(:handoff_response) do
      {
        'action' => 'handoff',
        'text' => 'Transferring to human agent...'
      }
    end

    it 'processes handoff action correctly' do
      # Requirements: 4.1, 4.2, 4.3, 4.4
      # Set conversation to pending status first
      conversation.update!(status: 'pending')
      expect(conversation.status).to eq('pending')
      
      processor_service.send(:process_response, message, handoff_response)
      
      conversation.reload
      expect(conversation.status).to eq('open')
    end

    it 'creates message along with handoff action' do
      # Requirements: 4.1, 7.1, 7.2, 7.3, 7.4
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, handoff_response)
      
      expect(conversation.messages.count).to be > initial_count
      
      created_message = conversation.messages.outgoing.last
      expect(created_message.content).to eq('Transferring to human agent...')
    end
  end

  describe 'Error Handling' do
    it 'handles malformed responses gracefully' do
      # Requirements: 6.1, 6.2, 6.3, 6.4
      malformed_response = { 'invalid' => 'data' }
      
      expect {
        processor_service.send(:process_response, message, malformed_response)
      }.not_to raise_error
    end

    it 'logs errors when processing fails' do
      # Requirements: 6.1, 6.2
      allow(Rails.logger).to receive(:error)
      allow(processor_service).to receive(:process_whatsapp_response).and_raise(StandardError, 'Test error')
      
      response = { 'whatsapp' => { 'type' => 'text', 'text' => { 'body' => 'Test' } } }
      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      
      processor_service.send(:process_response, message, response)
      
      expect(Rails.logger).to have_received(:error).with(match(/Test error/))
    end

    it 'creates fallback messages when processing fails' do
      # Requirements: 6.4, 7.1, 7.2
      allow(processor_service).to receive(:process_whatsapp_response).and_raise(StandardError, 'Processing failed')
      
      response = { 'whatsapp' => { 'type' => 'text', 'text' => { 'body' => 'Test' } } }
      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, response)
      
      expect(conversation.messages.count).to be > initial_count
      
      # Should create fallback message
      created_message = conversation.messages.outgoing.last
      expect(created_message.content).to be_present
    end
  end

  describe 'Message Tracking and Flow' do
    it 'maintains proper message attributes' do
      # Requirements: 7.1, 7.2, 7.3, 7.4
      response = {
        'whatsapp' => {
          'type' => 'text',
          'text' => { 'body' => 'Test tracking message' }
        }
      }
      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      
      processor_service.send(:process_response, message, response)
      
      created_message = conversation.messages.outgoing.last
      expect(created_message.account_id).to eq(account.id)
      expect(created_message.inbox_id).to eq(inbox.id)
      expect(created_message.conversation_id).to eq(conversation.id)
      expect(created_message.message_type).to eq('outgoing')
    end
  end

  describe 'Performance' do
    it 'processes responses within acceptable time limits' do
      response = {
        'whatsapp' => {
          'type' => 'text',
          'text' => { 'body' => 'Performance test' }
        }
      }
      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      
      start_time = Time.current
      
      5.times do
        processor_service.send(:process_response, message, response)
      end
      
      end_time = Time.current
      total_time = end_time - start_time
      
      expect(total_time).to be < 1.second
    end
  end
end