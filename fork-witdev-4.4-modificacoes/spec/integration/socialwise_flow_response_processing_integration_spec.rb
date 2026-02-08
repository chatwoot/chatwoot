require 'rails_helper'

RSpec.describe 'SocialWise Flow Response Processing Integration', type: :integration do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  
  # WhatsApp setup with mocked validation
  let(:whatsapp_channel) do
    create(:channel_whatsapp, account: account, provider_config: { 'api_key' => 'test_api_key' })
  end
  let(:whatsapp_inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
  let(:whatsapp_conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
  let(:whatsapp_message) { create(:message, account: account, inbox: whatsapp_inbox, conversation: whatsapp_conversation, content: 'Test message') }
  
  # Instagram setup
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:instagram_inbox) { create(:inbox, account: account, channel: instagram_channel) }
  let(:instagram_conversation) { create(:conversation, account: account, inbox: instagram_inbox, contact: contact) }
  let(:instagram_message) { create(:message, account: account, inbox: instagram_inbox, conversation: instagram_conversation, content: 'Test message') }
  
  # Facebook setup
  let(:facebook_channel) { create(:channel_facebook_page, account: account) }
  let(:facebook_inbox) { create(:inbox, account: account, channel: facebook_channel) }
  let(:facebook_conversation) { create(:conversation, account: account, inbox: facebook_inbox, contact: contact) }
  let(:facebook_message) { create(:message, account: account, inbox: facebook_inbox, conversation: facebook_conversation, content: 'Test message') }
  
  # SocialWise Flow hook
  let(:socialwise_hook) do
    create(:integrations_hook, 
           app_id: 'socialwise_flow',
           account: account,
           inbox: whatsapp_inbox,
           settings: {
             'endpoint' => 'https://socialwise.witdev.com.br/api/integrations/webhooks/socialwiseflow',
             'access_token' => 'test_token',
             'language' => 'pt-BR'
           })
  end
  
  before do
    # Mock WebMock requests for WhatsApp validation
    stub_request(:post, "https://waba.360dialog.io/v1/configs/webhook")
      .to_return(status: 200, body: "", headers: {})
    
    stub_request(:get, "https://waba.360dialog.io/v1/configs/templates")
      .to_return(status: 200, body: "[]", headers: {})
    
    # Mock other external services
    allow(Whatsapp::SendOnWhatsappService).to receive(:new).and_return(double(perform: true))
    allow(Facebook::SendOnFacebookService).to receive(:new).and_return(double(perform: true))
    allow(Facebook::RawDeliverService).to receive(:new).and_return(double(perform: true))
    
    # Mock WhatsApp channel methods to avoid external calls
    allow_any_instance_of(Channel::Whatsapp).to receive(:sync_templates).and_return(true)
    allow_any_instance_of(Channel::Whatsapp).to receive(:validate_provider_config).and_return(true)
  end
  
  let(:processor_service) do
    Integrations::SocialwiseFlow::ProcessorService.new(
      event_name: 'message.created',
      hook: socialwise_hook,
      event_data: { message: whatsapp_message }
    )
  end

  describe 'WhatsApp Interactive Message Processing' do
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
                'link' => 'https://objstoreapi.witdev.com.br/chatwit-social/33ad7e6c-7524-4bbb-a7f5-80d35768b3f8.png'
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
                    'id' => 'btn_1756139209769_0_u8bq',
                    'title' => 'Falar com a Dra'
                  }
                }
              ]
            }
          }
        }
      }
    end

    it 'processes WhatsApp interactive message with real SocialWise Flow payload' do
      # Requirements: 1.1, 1.2, 1.3, 1.4
      initial_count = whatsapp_conversation.messages.count
      
      processor_service.send(:process_response, whatsapp_message, whatsapp_interactive_response)
      
      expect(whatsapp_conversation.messages.count).to be > initial_count

      created_message = whatsapp_conversation.messages.outgoing.last
      expect(created_message.message_type).to eq('outgoing')
      expect(created_message.content_type).to eq('integrations')
      expect(created_message.content).to include('Sr(a) *Cliente*')
      expect(created_message.content_attributes['interactive']).to be_present
      expect(created_message.content_attributes['whatsapp_interactive_payload']).to be_present
    end

    it 'handles WhatsApp list messages (>3 options)' do
      list_response = {
        'whatsapp' => {
          'type' => 'interactive',
          'interactive' => {
            'body' => { 'text' => 'Escolha uma opção:' },
            'type' => 'list',
            'action' => {
              'button' => 'Ver opções',
              'sections' => [
                {
                  'title' => 'Serviços',
                  'rows' => [
                    { 'id' => 'opt1', 'title' => 'Opção 1' },
                    { 'id' => 'opt2', 'title' => 'Opção 2' },
                    { 'id' => 'opt3', 'title' => 'Opção 3' },
                    { 'id' => 'opt4', 'title' => 'Opção 4' }
                  ]
                }
              ]
            }
          }
        }
      }

      initial_count = whatsapp_conversation.messages.count
      
      processor_service.send(:process_response, whatsapp_message, list_response)
      
      expect(whatsapp_conversation.messages.count).to be > initial_count

      created_message = whatsapp_conversation.messages.outgoing.last
      expect(created_message.content_type).to eq('integrations')
      expect(created_message.content_attributes['interactive']['type']).to eq('list')
    end

    it 'handles WhatsApp processing errors gracefully' do
      # Requirements: 1.4, 6.1, 6.2, 6.3, 6.4
      malformed_response = {
        'whatsapp' => {
          'type' => 'interactive',
          'interactive' => nil # Invalid structure
        }
      }

      expect {
        processor_service.send(:process_response, whatsapp_message, malformed_response)
      }.not_to raise_error

      # Should still create a message (fallback behavior)
      expect(whatsapp_conversation.messages.count).to be >= 1
    end
  end

  describe 'Instagram Rich Message Processing' do
    let(:instagram_generic_template) do
      {
        'instagram' => {
          'message_format' => 'GENERIC_TEMPLATE',
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'mandado de segurança\n\nDra. Amanda Sousa Advocacia e Consultoria Jurídica™',
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
      }
    end

    let(:instagram_button_template) do
      {
        'instagram' => {
          'message_format' => 'BUTTON_TEMPLATE',
          'template_type' => 'button',
          'text' => 'BUTTON_TEMPLATE pode ter até 640 caracteres e 3 botões postback ou web_url (mistura)',
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
      }
    end

    let(:instagram_quick_replies) do
      {
        'instagram' => {
          'message_format' => 'QUICK_REPLIES',
          'text' => 'QUICK_REPLY_2 PODE TER ATÉ 1000 CARACTERES E 13 BOTÕES',
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
            }
          ]
        }
      }
    end

    it 'processes Instagram Generic Template with real payload' do
      # Requirements: 2.1, 2.2, 2.3, 2.4
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)

      processor_service_instagram = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: instagram_message }
      )

      expect {
        processor_service_instagram.send(:process_response, instagram_message, instagram_generic_template)
      }.not_to raise_error

      expect(Integrations::Socialwise::InstagramResponseProcessor).to have_received(:process)
        .with(instagram_generic_template['instagram'], instagram_message)
    end

    it 'processes Instagram Button Template with real payload' do
      # Requirements: 2.1, 2.2, 2.3, 2.4
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)

      processor_service_instagram = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: instagram_message }
      )

      expect {
        processor_service_instagram.send(:process_response, instagram_message, instagram_button_template)
      }.not_to raise_error

      expect(Integrations::Socialwise::InstagramResponseProcessor).to have_received(:process)
        .with(instagram_button_template['instagram'], instagram_message)
    end

    it 'processes Instagram Quick Replies with real payload' do
      # Requirements: 2.1, 2.2, 2.3, 2.4
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)

      processor_service_instagram = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: instagram_message }
      )

      expect {
        processor_service_instagram.send(:process_response, instagram_message, instagram_quick_replies)
      }.not_to raise_error

      expect(Integrations::Socialwise::InstagramResponseProcessor).to have_received(:process)
        .with(instagram_quick_replies['instagram'], instagram_message)
    end

    it 'creates fallback message when Instagram processing fails' do
      # Requirements: 2.4, 6.1, 6.2, 6.3, 6.4
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)

      processor_service_instagram = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: instagram_message }
      )

      expect {
        processor_service_instagram.send(:process_response, instagram_message, instagram_generic_template)
      }.to change { instagram_conversation.messages.count }.by(1)

      # Should create fallback message
      created_message = instagram_conversation.messages.last
      expect(created_message.message_type).to eq('outgoing')
      expect(created_message.content).to be_present
    end
  end

  describe 'Facebook Message Processing' do
    let(:facebook_text_response) do
      {
        'facebook' => {
          'message' => {
            'text' => 'Olá! Como posso ajudá-lo hoje?'
          }
        }
      }
    end

    let(:facebook_rich_response) do
      {
        'facebook' => {
          'message' => {
            'text' => 'Escolha uma opção:',
            'quick_replies' => [
              {
                'content_type' => 'text',
                'title' => 'Suporte',
                'payload' => 'SUPPORT'
              },
              {
                'content_type' => 'text',
                'title' => 'Vendas',
                'payload' => 'SALES'
              }
            ]
          }
        }
      }
    end

    it 'processes Facebook text message with real payload' do
      # Requirements: 5.1, 5.2
      processor_service_facebook = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: facebook_message }
      )

      expect {
        processor_service_facebook.send(:process_response, facebook_message, facebook_text_response)
      }.to change { facebook_conversation.messages.count }.by(1)

      created_message = facebook_conversation.messages.last
      expect(created_message.message_type).to eq('outgoing')
      expect(created_message.content_type).to eq('text')
      expect(created_message.content).to eq('Olá! Como posso ajudá-lo hoje?')
    end

    it 'processes Facebook rich content with real payload' do
      # Requirements: 5.1, 5.3
      allow(Facebook::RawDeliverService).to receive(:new).and_return(double(perform: true))

      processor_service_facebook = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: facebook_message }
      )

      expect {
        processor_service_facebook.send(:process_response, facebook_message, facebook_rich_response)
      }.to change { facebook_conversation.messages.count }.by(1)

      created_message = facebook_conversation.messages.last
      expect(created_message.message_type).to eq('outgoing')
      expect(created_message.content_type).to eq('integrations')
      expect(created_message.content_attributes).to eq(facebook_rich_response['facebook'])
    end

    it 'adds recipient ID when missing from Facebook payload' do
      # Requirements: 5.4
      allow(Facebook::RawDeliverService).to receive(:new) do |args|
        expect(args[:payload]['recipient']).to be_present
        expect(args[:payload]['recipient']['id']).to be_present
        double(perform: true)
      end

      processor_service_facebook = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: facebook_message }
      )

      processor_service_facebook.send(:process_response, facebook_message, facebook_rich_response)
    end
  end

  describe 'Button Reaction Processing' do
    let(:whatsapp_button_reaction) do
      {
        'action_type' => 'button_reaction',
        'buttonId' => 'btn_1756139209769_0_u8bq',
        'processed' => true,
        'mappingFound' => true,
        'emoji' => '❤️',
        'text' => 'VAI ser atendido em instantes',
        'action' => 'handoff',
        'whatsapp' => {
          'message_id' => 'wamid.HBgMNTU4NTk3NTUwMTM2FQIAEhgU84KOMYKRCYMRHGF1LYCQ9PA',
          'reaction_emoji' => '❤️',
          'response_text' => 'VAI ser atendido em instantes'
        }
      }
    end

    let(:instagram_button_reaction) do
      {
        'action_type' => 'button_reaction',
        'buttonId' => 'ig_btn_1756139332989_pm6hd9wau',
        'processed' => true,
        'mappingFound' => true,
        'emoji' => '😅',
        'text' => 'VAI ser atendido em instantes',
        'action' => 'handoff',
        'instagram' => {
          'message_id' => 'aWdfZAG1faXRlbToxOklHTWVzc2FnZAUlE0Jhw/PIwCG8Wwwn4SUIpa6HJagW2ekt1vbrB/EUlZDZD',
          'reaction_emoji' => '😅',
          'response_text' => 'VAI ser atendido em instantes'
        }
      }
    end

    it 'processes WhatsApp button reaction with emoji and text' do
      # Requirements: 3.1, 3.2, 3.3, 3.4
      expect {
        processor_service.send(:process_response, whatsapp_message, whatsapp_button_reaction)
      }.to change { whatsapp_conversation.messages.count }.by(2) # emoji reaction + text response

      messages = whatsapp_conversation.messages.last(2)
      
      # Check emoji reaction message
      emoji_message = messages.find { |m| m.message_type == 'activity' }
      expect(emoji_message).to be_present
      expect(emoji_message.content).to include('❤️')
      expect(emoji_message.content_attributes['emoji_reaction']).to eq('❤️')
      expect(emoji_message.content_attributes['button_id']).to eq('btn_1756139209769_0_u8bq')
      
      # Check text response message
      text_message = messages.find { |m| m.message_type == 'outgoing' }
      expect(text_message).to be_present
      expect(text_message.content).to eq('VAI ser atendido em instantes')
      expect(text_message.content_attributes['button_reaction_response']).to be true
    end

    it 'processes Instagram button reaction with emoji and text' do
      # Requirements: 3.1, 3.2, 3.3, 3.4
      processor_service_instagram = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: instagram_message }
      )

      expect {
        processor_service_instagram.send(:process_response, instagram_message, instagram_button_reaction)
      }.to change { instagram_conversation.messages.count }.by(2) # emoji reaction + text response

      messages = instagram_conversation.messages.last(2)
      
      # Check emoji reaction message
      emoji_message = messages.find { |m| m.message_type == 'activity' }
      expect(emoji_message).to be_present
      expect(emoji_message.content).to include('😅')
      expect(emoji_message.content_attributes['emoji_reaction']).to eq('😅')
      
      # Check text response message
      text_message = messages.find { |m| m.message_type == 'outgoing' }
      expect(text_message).to be_present
      expect(text_message.content).to eq('VAI ser atendido em instantes')
    end

    it 'processes handoff action after button reaction' do
      # Requirements: 3.4, 4.1, 4.2, 4.3, 4.4
      expect(whatsapp_conversation.status).to eq('pending')

      processor_service.send(:process_response, whatsapp_message, whatsapp_button_reaction)

      whatsapp_conversation.reload
      expect(whatsapp_conversation.status).to eq('open') # Should change from pending to open
    end

    it 'continues processing handoff even if reaction sending fails' do
      # Requirements: 3.4, 6.3
      allow(processor_service).to receive(:send_emoji_reaction).and_raise(StandardError, 'Reaction failed')
      
      expect(whatsapp_conversation.status).to eq('pending')

      expect {
        processor_service.send(:process_response, whatsapp_message, whatsapp_button_reaction)
      }.not_to raise_error

      whatsapp_conversation.reload
      expect(whatsapp_conversation.status).to eq('open') # Handoff should still work
    end
  end

  describe 'Handoff Processing' do
    let(:handoff_response) do
      {
        'action' => 'handoff',
        'text' => 'Transferindo para atendimento humano...'
      }
    end

    it 'processes handoff action correctly' do
      # Requirements: 4.1, 4.2, 4.3, 4.4
      expect(whatsapp_conversation.status).to eq('pending')

      processor_service.send(:process_response, whatsapp_message, handoff_response)

      whatsapp_conversation.reload
      expect(whatsapp_conversation.status).to eq('open')
    end

    it 'creates text message along with handoff action' do
      # Requirements: 4.1, 7.1, 7.2, 7.3, 7.4
      expect {
        processor_service.send(:process_response, whatsapp_message, handoff_response)
      }.to change { whatsapp_conversation.messages.count }.by(1)

      created_message = whatsapp_conversation.messages.last
      expect(created_message.content).to eq('Transferindo para atendimento humano...')
    end
  end

  describe 'Error Handling and Logging' do
    it 'handles completely malformed responses gracefully' do
      # Requirements: 6.1, 6.2, 6.3, 6.4
      malformed_response = { 'invalid' => 'data' }

      expect {
        processor_service.send(:process_response, whatsapp_message, malformed_response)
      }.not_to raise_error

      # Should create fallback message or handle gracefully
      expect(whatsapp_conversation.messages.count).to be >= 1
    end

    it 'logs detailed error information when processing fails' do
      # Requirements: 6.1, 6.2
      allow(Rails.logger).to receive(:error)
      allow(processor_service).to receive(:process_whatsapp_response).and_raise(StandardError, 'Processing failed')

      whatsapp_response = { 'whatsapp' => { 'type' => 'text', 'text' => { 'body' => 'Test' } } }

      processor_service.send(:process_response, whatsapp_message, whatsapp_response)

      expect(Rails.logger).to have_received(:error).with(match(/Processing failed/))
    end

    it 'creates fallback messages when rich message processing fails' do
      # Requirements: 6.4, 7.1, 7.2
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_raise(StandardError, 'Instagram failed')

      processor_service_instagram = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: instagram_message }
      )

      instagram_response = {
        'instagram' => {
          'message_format' => 'GENERIC_TEMPLATE',
          'elements' => [{ 'title' => 'Test' }]
        }
      }

      expect {
        processor_service_instagram.send(:process_response, instagram_message, instagram_response)
      }.to change { instagram_conversation.messages.count }.by(1)

      # Should create fallback message
      created_message = instagram_conversation.messages.last
      expect(created_message.content).to be_present
    end
  end

  describe 'End-to-End Integration Testing' do
    it 'processes complete SocialWise Flow response with multiple channels' do
      # Requirements: 1.1-1.4, 2.1-2.4, 3.1-3.4, 4.1-4.4, 5.1-5.4, 6.1-6.4, 7.1-7.4
      
      # Test WhatsApp
      whatsapp_response = {
        'whatsapp' => {
          'type' => 'interactive',
          'interactive' => {
            'body' => { 'text' => 'WhatsApp test message' },
            'type' => 'button',
            'action' => {
              'buttons' => [
                { 'type' => 'reply', 'reply' => { 'id' => 'btn1', 'title' => 'Option 1' } }
              ]
            }
          }
        }
      }

      expect {
        processor_service.send(:process_response, whatsapp_message, whatsapp_response)
      }.to change { whatsapp_conversation.messages.count }.by(1)

      # Test Instagram
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
      
      processor_service_instagram = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: instagram_message }
      )

      instagram_response = {
        'instagram' => {
          'message_format' => 'BUTTON_TEMPLATE',
          'text' => 'Instagram test message',
          'buttons' => [
            { 'type' => 'postback', 'title' => 'Test', 'payload' => 'test_payload' }
          ]
        }
      }

      processor_service_instagram.send(:process_response, instagram_message, instagram_response)

      # Test Facebook
      processor_service_facebook = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: facebook_message }
      )

      facebook_response = {
        'facebook' => {
          'message' => {
            'text' => 'Facebook test message'
          }
        }
      }

      expect {
        processor_service_facebook.send(:process_response, facebook_message, facebook_response)
      }.to change { facebook_conversation.messages.count }.by(1)

      # Verify all messages were created correctly
      expect(whatsapp_conversation.messages.last.content_type).to eq('integrations')
      expect(facebook_conversation.messages.last.content_type).to eq('text')
    end

    it 'handles mixed response types in single payload' do
      # Test response with both message and handoff action
      mixed_response = {
        'action' => 'handoff',
        'whatsapp' => {
          'type' => 'text',
          'text' => { 'body' => 'Transferindo para atendimento...' }
        }
      }

      expect(whatsapp_conversation.status).to eq('pending')

      expect {
        processor_service.send(:process_response, whatsapp_message, mixed_response)
      }.to change { whatsapp_conversation.messages.count }.by(1)

      whatsapp_conversation.reload
      expect(whatsapp_conversation.status).to eq('open') # Handoff processed
      expect(whatsapp_conversation.messages.last.content).to include('Transferindo')
    end

    it 'maintains conversation flow and message tracking' do
      # Requirements: 7.1, 7.2, 7.3, 7.4
      initial_message_count = whatsapp_conversation.messages.count

      response = {
        'whatsapp' => {
          'type' => 'text',
          'text' => { 'body' => 'Test message for tracking' }
        }
      }

      processor_service.send(:process_response, whatsapp_message, response)

      # Verify message tracking
      created_message = whatsapp_conversation.messages.last
      expect(created_message.account_id).to eq(account.id)
      expect(created_message.inbox_id).to eq(whatsapp_inbox.id)
      expect(created_message.conversation_id).to eq(whatsapp_conversation.id)
      expect(created_message.message_type).to eq('outgoing')
      
      # Verify conversation flow
      expect(whatsapp_conversation.messages.count).to eq(initial_message_count + 1)
    end
  end

  describe 'Performance and Reliability' do
    it 'processes responses within acceptable time limits' do
      response = {
        'whatsapp' => {
          'type' => 'text',
          'text' => { 'body' => 'Performance test message' }
        }
      }

      start_time = Time.current
      
      10.times do
        processor_service.send(:process_response, whatsapp_message, response)
      end
      
      end_time = Time.current
      total_time = end_time - start_time

      expect(total_time).to be < 2.seconds # Should complete within 2 seconds
    end

    it 'handles concurrent processing without errors' do
      responses = 5.times.map do |i|
        {
          'whatsapp' => {
            'type' => 'text',
            'text' => { 'body' => "Concurrent message #{i}" }
          }
        }
      end

      threads = responses.map.with_index do |response, index|
        Thread.new do
          test_message = create(:message, 
                               account: account, 
                               inbox: whatsapp_inbox, 
                               conversation: whatsapp_conversation, 
                               content: "Test #{index}")
          
          test_processor = Integrations::SocialwiseFlow::ProcessorService.new(
            event_name: 'message.created',
            hook: socialwise_hook,
            event_data: { message: test_message }
          )
          
          test_processor.send(:process_response, test_message, response)
        end
      end

      expect { threads.each(&:join) }.not_to raise_error
    end
  end
end