require 'rails_helper'

RSpec.describe 'SocialWise Flow End-to-End Integration', type: :integration do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  
  # Create different channel types for multi-channel testing
  let(:whatsapp_inbox) { create(:inbox, account: account, channel: create(:channel_whatsapp, account: account)) }
  let(:facebook_inbox) { create(:inbox, account: account, channel: create(:channel_facebook_page, account: account)) }
  
  let(:whatsapp_conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact, status: 'pending') }
  let(:facebook_conversation) { create(:conversation, account: account, inbox: facebook_inbox, contact: contact, status: 'pending') }
  
  let(:whatsapp_message) { create(:message, account: account, inbox: whatsapp_inbox, conversation: whatsapp_conversation, content: 'Test WhatsApp message') }
  let(:facebook_message) { create(:message, account: account, inbox: facebook_inbox, conversation: facebook_conversation, content: 'Test Facebook message') }
  
  let(:socialwise_hook) do
    create(:integrations_hook, 
           app_id: 'socialwise_flow',
           account: account,
           settings: {
             'endpoint' => 'https://socialwise.witdev.com.br/api/integrations/webhooks/socialwiseflow',
             'access_token' => 'test_token',
             'language' => 'pt-BR'
           })
  end

  before do
    # Mock external services to avoid actual API calls
    allow(HTTParty).to receive(:post).and_return(double(success?: true, parsed_response: {}))
    allow(Whatsapp::SendOnWhatsappService).to receive(:new).and_return(double(perform: true))
    allow(Facebook::SendOnFacebookService).to receive(:new).and_return(double(perform: true))
    allow(Facebook::RawDeliverService).to receive(:new).and_return(double(perform: true))
    allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
    
    # Mock WhatsApp channel provider service for interactive messages
    mock_provider_service = double('provider_service')
    allow(mock_provider_service).to receive(:send_interactive_payload).and_return('mock_message_id')
    allow_any_instance_of(Channel::Whatsapp).to receive(:provider_service).and_return(mock_provider_service)
  end

  describe 'Complete Flow from SocialWise Flow Webhook to Message Delivery' do
    context 'WhatsApp Channel' do
      let(:processor_service) do
        Integrations::SocialwiseFlow::ProcessorService.new(
          event_name: 'message.created',
          hook: socialwise_hook,
          event_data: { message: whatsapp_message }
        )
      end

      it 'processes complete WhatsApp interactive message flow' do
        # Requirement 1.1, 1.2, 1.3, 1.4: WhatsApp interactive message processing
        whatsapp_response = {
          'whatsapp' => {
            'type' => 'interactive',
            'interactive' => {
              'body' => { 'text' => 'Como posso ajudá-lo hoje?' },
              'type' => 'button',
              'action' => {
                'buttons' => [
                  {
                    'type' => 'reply',
                    'reply' => { 'id' => 'btn_help', 'title' => 'Preciso de Ajuda' }
                  }
                ]
              }
            }
          }
        }

        # Mock successful HTTP response from SocialWise Flow
        allow(HTTParty).to receive(:post).and_return(
          double(success?: true, parsed_response: whatsapp_response)
        )

        initial_message_count = whatsapp_conversation.messages.count
        
        # Execute the complete flow
        processor_service.perform
        
        # Verify message was created (Requirement 7.1, 7.2)
        whatsapp_conversation.reload
        expect(whatsapp_conversation.messages.count).to be > initial_message_count
        
        created_message = whatsapp_conversation.messages.outgoing.last
        expect(created_message).to be_present
        expect(created_message.content_type).to eq('integrations')
        expect(created_message.content_attributes['interactive']).to be_present
        expect(created_message.account_id).to eq(account.id)
        expect(created_message.inbox_id).to eq(whatsapp_inbox.id)
      end

      it 'processes WhatsApp text message flow' do
        whatsapp_text_response = {
          'whatsapp' => {
            'type' => 'text',
            'text' => { 'body' => 'Olá! Como posso ajudá-lo?' }
          }
        }

        allow(HTTParty).to receive(:post).and_return(
          double(success?: true, parsed_response: whatsapp_text_response)
        )

        initial_message_count = whatsapp_conversation.messages.count
        
        processor_service.perform
        
        whatsapp_conversation.reload
        expect(whatsapp_conversation.messages.count).to be > initial_message_count
        
        created_message = whatsapp_conversation.messages.outgoing.last
        expect(created_message.content_type).to eq('text')
        expect(created_message.content).to include('Olá! Como posso ajudá-lo?')
      end
    end

    context 'Instagram Channel (Facebook Page)' do
      let(:processor_service) do
        Integrations::SocialwiseFlow::ProcessorService.new(
          event_name: 'message.created',
          hook: socialwise_hook,
          event_data: { message: facebook_message }
        )
      end

      it 'processes complete Instagram rich message flow' do
        # Requirement 2.1, 2.2, 2.3, 2.4: Instagram rich message processing
        instagram_response = {
          'instagram' => {
            'message_format' => 'GENERIC_TEMPLATE',
            'template_type' => 'generic',
            'elements' => [
              {
                'title' => 'Nossos Serviços',
                'buttons' => [
                  {
                    'type' => 'postback',
                    'title' => 'Saiba Mais',
                    'payload' => 'ig_btn_services'
                  }
                ],
                'image_url' => 'https://example.com/image.jpg'
              }
            ]
          }
        }

        allow(HTTParty).to receive(:post).and_return(
          double(success?: true, parsed_response: instagram_response)
        )

        processor_service.perform
        
        # Verify Instagram processor was called
        expect(Integrations::Socialwise::InstagramResponseProcessor).to have_received(:process)
          .with(instagram_response['instagram'], facebook_message)
      end

      it 'processes Facebook text message flow' do
        # Requirement 5.1, 5.2, 5.3, 5.4: Facebook message processing
        facebook_response = {
          'facebook' => {
            'message' => {
              'text' => 'Bem-vindo ao nosso atendimento!'
            }
          }
        }

        allow(HTTParty).to receive(:post).and_return(
          double(success?: true, parsed_response: facebook_response)
        )

        initial_message_count = facebook_conversation.messages.count
        
        processor_service.perform
        
        facebook_conversation.reload
        expect(facebook_conversation.messages.count).to be > initial_message_count
        
        created_message = facebook_conversation.messages.outgoing.last
        expect(created_message.content).to eq('Bem-vindo ao nosso atendimento!')
        expect(created_message.content_type).to eq('text')
      end
    end
  end

  describe 'Handoff Functionality Verification' do
    let(:processor_service) do
      Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: whatsapp_message }
      )
    end

    it 'correctly processes handoff action' do
      # Requirement 4.1, 4.2, 4.3, 4.4: Handoff processing
      handoff_response = {
        'action' => 'handoff',
        'whatsapp' => {
          'type' => 'text',
          'text' => { 'body' => 'Transferindo para um especialista...' }
        }
      }

      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: handoff_response)
      )

      # Verify initial conversation status
      expect(whatsapp_conversation.status).to eq('pending')
      
      processor_service.perform
      
      # Verify handoff was processed (Requirement 4.2)
      whatsapp_conversation.reload
      expect(whatsapp_conversation.status).to eq('open')
      
      # Verify message was also created
      created_message = whatsapp_conversation.messages.outgoing.last
      expect(created_message).to be_present
      expect(created_message.content).to include('Transferindo para um especialista')
    end

    it 'processes button reaction with handoff' do
      # Requirement 3.1, 3.2, 3.3, 3.4: Button reaction with handoff
      button_reaction_response = {
        'action_type' => 'button_reaction',
        'buttonId' => 'btn_handoff_test',
        'processed' => true,
        'mappingFound' => true,
        'emoji' => '✅',
        'text' => 'Conectando com nossa equipe...',
        'action' => 'handoff',
        'whatsapp' => {
          'message_id' => 'wamid.test_handoff',
          'reaction_emoji' => '✅',
          'response_text' => 'Conectando com nossa equipe...'
        }
      }

      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: button_reaction_response)
      )

      expect(whatsapp_conversation.status).to eq('pending')
      initial_message_count = whatsapp_conversation.messages.count
      
      processor_service.perform
      
      # Verify handoff was processed
      whatsapp_conversation.reload
      expect(whatsapp_conversation.status).to eq('open')
      
      # Verify reaction messages were created
      expect(whatsapp_conversation.messages.count).to be > initial_message_count
      
      # Verify emoji reaction message
      activity_messages = whatsapp_conversation.messages.where(message_type: 'activity')
      expect(activity_messages.count).to be > 0
      
      emoji_message = activity_messages.find { |m| m.content_attributes['emoji_reaction'] == '✅' }
      expect(emoji_message).to be_present
      
      # Verify text response message
      text_messages = whatsapp_conversation.messages.where(message_type: 'outgoing')
      text_message = text_messages.find { |m| m.content.include?('Conectando com nossa equipe') }
      expect(text_message).to be_present
    end
  end

  describe 'Multi-Channel Simultaneous Testing' do
    it 'processes messages from multiple channels simultaneously' do
      # Create processors for both channels
      whatsapp_processor = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: whatsapp_message }
      )
      
      facebook_processor = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: facebook_message }
      )

      # Different responses for each channel
      whatsapp_response = {
        'whatsapp' => {
          'type' => 'interactive',
          'interactive' => {
            'body' => { 'text' => 'WhatsApp Interactive Message' },
            'type' => 'button',
            'action' => {
              'buttons' => [{ 'type' => 'reply', 'reply' => { 'id' => 'wa_btn', 'title' => 'WhatsApp Button' } }]
            }
          }
        }
      }

      instagram_response = {
        'instagram' => {
          'message_format' => 'BUTTON_TEMPLATE',
          'template_type' => 'button',
          'text' => 'Instagram Button Template',
          'buttons' => [
            { 'type' => 'postback', 'title' => 'Instagram Button', 'payload' => 'ig_btn' }
          ]
        }
      }

      # Mock different responses for each channel
      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: whatsapp_response),
        double(success?: true, parsed_response: instagram_response)
      )

      initial_whatsapp_count = whatsapp_conversation.messages.count
      initial_facebook_count = facebook_conversation.messages.count

      # Process both channels
      whatsapp_processor.perform
      facebook_processor.perform

      # Verify both channels processed correctly
      whatsapp_conversation.reload
      facebook_conversation.reload

      expect(whatsapp_conversation.messages.count).to be > initial_whatsapp_count
      expect(facebook_conversation.messages.count).to be >= initial_facebook_count

      # Verify WhatsApp message
      whatsapp_message = whatsapp_conversation.messages.outgoing.last
      expect(whatsapp_message.content_type).to eq('integrations')
      expect(whatsapp_message.content).to include('WhatsApp Interactive Message')

      # Verify Instagram processor was called
      expect(Integrations::Socialwise::InstagramResponseProcessor).to have_received(:process)
        .with(instagram_response['instagram'], facebook_message)
    end

    it 'handles handoff actions across multiple channels' do
      # Test handoff on both channels simultaneously
      handoff_response = { 'action' => 'handoff' }

      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: handoff_response)
      )

      whatsapp_processor = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: whatsapp_message }
      )
      
      facebook_processor = Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: facebook_message }
      )

      # Both conversations should be pending initially
      expect(whatsapp_conversation.status).to eq('pending')
      expect(facebook_conversation.status).to eq('pending')

      # Process handoff on both channels
      whatsapp_processor.perform
      facebook_processor.perform

      # Both conversations should be open after handoff
      whatsapp_conversation.reload
      facebook_conversation.reload
      
      expect(whatsapp_conversation.status).to eq('open')
      expect(facebook_conversation.status).to eq('open')
    end
  end

  describe 'Logging and Error Reporting Validation' do
    let(:processor_service) do
      Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: whatsapp_message }
      )
    end

    it 'logs detailed information during successful processing' do
      # Requirement 6.1, 7.1, 7.2, 7.3, 7.4: Proper logging and tracking
      successful_response = {
        'whatsapp' => {
          'type' => 'text',
          'text' => { 'body' => 'Success message' }
        }
      }

      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: successful_response)
      )

      # Capture log output
      expect(Rails.logger).to receive(:info).with(/SOCIALWISE-FLOW.*PROCESSING RESPONSE/).at_least(:once)
      expect(Rails.logger).to receive(:info).with(/SOCIALWISE-FLOW.*Message ID: #{whatsapp_message.id}/).at_least(:once)
      expect(Rails.logger).to receive(:info).with(/SOCIALWISE-FLOW.*Channel type: Channel::Whatsapp/).at_least(:once)
      expect(Rails.logger).to receive(:info).with(/SOCIALWISE-FLOW.*WHATSAPP.*Message created successfully/).at_least(:once)

      processor_service.perform
    end

    it 'logs detailed error information during failures' do
      # Requirement 6.1, 6.2, 6.3, 6.4: Error handling and logging
      malformed_response = {
        'whatsapp' => {
          'type' => 'interactive',
          'interactive' => nil # This will cause an error
        }
      }

      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: malformed_response)
      )

      # Expect error logging
      expect(Rails.logger).to receive(:error).with(/SOCIALWISE-FLOW.*Exception class/).at_least(:once)
      expect(Rails.logger).to receive(:error).with(/SOCIALWISE-FLOW.*Exception message/).at_least(:once)
      expect(Rails.logger).to receive(:error).with(/SOCIALWISE-FLOW.*Message ID: #{whatsapp_message.id}/).at_least(:once)
      expect(Rails.logger).to receive(:error).with(/SOCIALWISE-FLOW.*Backtrace/).at_least(:once)

      # Should not raise error, should handle gracefully
      expect { processor_service.perform }.not_to raise_error
    end

    it 'creates fallback messages when processing fails' do
      # Requirement 6.4: Create fallback text message with raw response when format is invalid
      invalid_response = {
        'invalid_format' => 'This should cause fallback message creation'
      }

      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: invalid_response)
      )

      initial_message_count = whatsapp_conversation.messages.count
      
      processor_service.perform
      
      # Should create a fallback message
      whatsapp_conversation.reload
      expect(whatsapp_conversation.messages.count).to be > initial_message_count
      
      # Verify fallback message was created
      created_message = whatsapp_conversation.messages.outgoing.last
      expect(created_message).to be_present
      expect(created_message.content).to be_present
    end

    it 'handles HTTP request failures gracefully' do
      # Test network/HTTP failures
      allow(HTTParty).to receive(:post).and_raise(StandardError.new('Network error'))

      expect(Rails.logger).to receive(:error).with(/SOCIALWISE-FLOW.*Request failed/).at_least(:once)
      expect(Rails.logger).to receive(:error).with(/SOCIALWISE-FLOW.*Network error/).at_least(:once)

      # Should not raise error
      expect { processor_service.perform }.not_to raise_error
    end

    it 'logs handoff processing failures but continues' do
      # Requirement 6.3: Log handoff action failures but don't block message processing
      handoff_response = {
        'action' => 'handoff',
        'whatsapp' => {
          'type' => 'text',
          'text' => { 'body' => 'Message with handoff' }
        }
      }

      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: handoff_response)
      )

      # Mock handoff failure
      allow(whatsapp_conversation).to receive(:bot_handoff!).and_raise(StandardError.new('Handoff failed'))

      expect(Rails.logger).to receive(:error).with(/SOCIALWISE-FLOW.*Action processing failed/).at_least(:once)
      expect(Rails.logger).to receive(:error).with(/SOCIALWISE-FLOW.*Handoff failed/).at_least(:once)

      initial_message_count = whatsapp_conversation.messages.count
      
      # Should not raise error and should still create message
      expect { processor_service.perform }.not_to raise_error
      
      # Message should still be created despite handoff failure
      whatsapp_conversation.reload
      expect(whatsapp_conversation.messages.count).to be > initial_message_count
    end
  end

  describe 'Message Tracking and Conversation Flow' do
    let(:processor_service) do
      Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: whatsapp_message }
      )
    end

    it 'maintains proper conversation flow and status' do
      # Requirement 7.4: Maintain proper conversation flow and status
      response_with_handoff = {
        'action' => 'handoff',
        'whatsapp' => {
          'type' => 'text',
          'text' => { 'body' => 'Transferindo para atendimento humano...' }
        }
      }

      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: response_with_handoff)
      )

      # Initial state
      expect(whatsapp_conversation.status).to eq('pending')
      initial_message_count = whatsapp_conversation.messages.count

      processor_service.perform

      # Verify conversation state change
      whatsapp_conversation.reload
      expect(whatsapp_conversation.status).to eq('open')
      
      # Verify message tracking
      expect(whatsapp_conversation.messages.count).to be > initial_message_count
      
      created_message = whatsapp_conversation.messages.outgoing.last
      expect(created_message.account_id).to eq(account.id)
      expect(created_message.inbox_id).to eq(whatsapp_inbox.id)
      expect(created_message.message_type).to eq('outgoing')
    end

    it 'records rich messages with appropriate content_attributes for dashboard display' do
      # Requirement 7.2: Record rich messages with appropriate content_attributes for dashboard display
      rich_response = {
        'whatsapp' => {
          'type' => 'interactive',
          'interactive' => {
            'body' => { 'text' => 'Escolha uma opção:' },
            'type' => 'button',
            'action' => {
              'buttons' => [
                { 'type' => 'reply', 'reply' => { 'id' => 'opt1', 'title' => 'Opção 1' } },
                { 'type' => 'reply', 'reply' => { 'id' => 'opt2', 'title' => 'Opção 2' } }
              ]
            }
          }
        }
      }

      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: rich_response)
      )

      processor_service.perform

      whatsapp_conversation.reload
      created_message = whatsapp_conversation.messages.outgoing.last
      
      expect(created_message.content_type).to eq('integrations')
      expect(created_message.content_attributes).to be_present
      expect(created_message.content_attributes['interactive']).to be_present
      expect(created_message.content_attributes['interactive']['type']).to eq('button')
      expect(created_message.content_attributes['interactive']['action']['buttons'].count).to eq(2)
    end
  end

  describe 'Performance and Reliability' do
    let(:processor_service) do
      Integrations::SocialwiseFlow::ProcessorService.new(
        event_name: 'message.created',
        hook: socialwise_hook,
        event_data: { message: whatsapp_message }
      )
    end

    it 'handles large payloads efficiently' do
      # Test with large interactive message payload
      large_response = {
        'whatsapp' => {
          'type' => 'interactive',
          'interactive' => {
            'body' => { 'text' => 'A' * 1000 }, # Large text content
            'type' => 'list',
            'action' => {
              'button' => 'Ver Opções',
              'sections' => [
                {
                  'title' => 'Seção 1',
                  'rows' => (1..10).map do |i|
                    {
                      'id' => "option_#{i}",
                      'title' => "Opção #{i}",
                      'description' => "Descrição da opção #{i}" * 10
                    }
                  end
                }
              ]
            }
          }
        }
      }

      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: large_response)
      )

      start_time = Time.current
      
      expect { processor_service.perform }.not_to raise_error
      
      processing_time = Time.current - start_time
      expect(processing_time).to be < 5.seconds # Should process within reasonable time

      # Verify message was created correctly
      whatsapp_conversation.reload
      created_message = whatsapp_conversation.messages.outgoing.last
      expect(created_message).to be_present
      expect(created_message.content_attributes['interactive']['action']['sections'].first['rows'].count).to eq(10)
    end

    it 'handles concurrent processing without conflicts' do
      # Test concurrent processing of multiple messages
      response = {
        'whatsapp' => {
          'type' => 'text',
          'text' => { 'body' => 'Concurrent test message' }
        }
      }

      allow(HTTParty).to receive(:post).and_return(
        double(success?: true, parsed_response: response)
      )

      # Create multiple messages for concurrent processing
      messages = 3.times.map do |i|
        create(:message, 
               account: account, 
               inbox: whatsapp_inbox, 
               conversation: whatsapp_conversation, 
               content: "Concurrent message #{i}")
      end

      processors = messages.map do |msg|
        Integrations::SocialwiseFlow::ProcessorService.new(
          event_name: 'message.created',
          hook: socialwise_hook,
          event_data: { message: msg }
        )
      end

      initial_count = whatsapp_conversation.messages.count

      # Process concurrently using threads
      threads = processors.map do |processor|
        Thread.new { processor.perform }
      end

      threads.each(&:join)

      # Verify all messages were processed
      whatsapp_conversation.reload
      expect(whatsapp_conversation.messages.count).to be >= initial_count + 3
    end
  end
end