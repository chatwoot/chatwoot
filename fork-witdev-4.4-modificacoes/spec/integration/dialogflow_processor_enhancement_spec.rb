# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dialogflow Processor Enhancement Integration', type: :integration do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account, sync_templates: false, validate_provider_config: false) }
  let(:whatsapp_inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:instagram_conversation) { create(:conversation, inbox: instagram_inbox, contact: contact, account: account) }
  let(:whatsapp_conversation) { create(:conversation, inbox: whatsapp_inbox, contact: contact, account: account) }
  let(:instagram_message) { create(:message, conversation: instagram_conversation, account: account, inbox: instagram_inbox) }
  let(:whatsapp_message) { create(:message, conversation: whatsapp_conversation, account: account, inbox: whatsapp_inbox) }
  
  let(:hook) do
    create(:integrations_hook, 
           app_id: 'dialogflow', 
           account: account,
           inbox: instagram_inbox,
           hook_type: 'inbox',
           settings: {
             'project_id' => 'test_project',
             'credentials' => { 'type' => 'service_account' },
             'region' => 'global'
           })
  end

  let(:instagram_event_data) do
    {
      message: instagram_message,
      conversation: instagram_conversation,
      contact: contact,
      inbox: instagram_inbox
    }
  end

  let(:whatsapp_event_data) do
    {
      message: whatsapp_message,
      conversation: whatsapp_conversation,
      contact: contact,
      inbox: whatsapp_inbox
    }
  end

  let(:instagram_service) { Integrations::Dialogflow::ProcessorService.new(event_name: 'message.created', event_data: instagram_event_data, hook: hook) }
  let(:whatsapp_service) { Integrations::Dialogflow::ProcessorService.new(event_name: 'message.created', event_data: whatsapp_event_data, hook: hook) }

  before do
    # Mock Instagram API calls
    stub_request(:post, %r{graph\.instagram\.com/v22\.0/.*/messages})
      .to_return(status: 200, body: { message_id: 'test_message_id' }.to_json)
    
    # Mock WhatsApp API calls to prevent real HTTP requests
    stub_request(:post, %r{waba\.360dialog\.io/v1/configs/webhook})
      .to_return(status: 200, body: {}.to_json)
    
    # Mock GlobalConfig for human agent tag
    allow(GlobalConfig).to receive(:get).with('ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT')
                                        .and_return({ 'ENABLE_INSTAGRAM_CHANNEL_HUMAN_AGENT' => false })
    
    # Mock account feature_enabled? with default return value
    allow(account).to receive(:feature_enabled?).and_return(false)
    allow(account).to receive(:feature_enabled?).with('SOCIALWISE_RICH_DASHBOARD').and_return(false)
  end

  describe 'socialwiseResponse detection in Dialogflow responses' do
    context 'when Dialogflow response contains socialwiseResponse' do
      let(:dialogflow_response_with_socialwise) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'payload' => {
                  'socialwiseResponse' => {
                    'message_format' => 'GENERIC_TEMPLATE',
                    'payload' => {
                      'template_type' => 'generic',
                      'elements' => [
                        {
                          'title' => 'Product 1',
                          'subtitle' => 'Amazing product',
                          'image_url' => 'https://example.com/image1.jpg',
                          'buttons' => [
                            {
                              'type' => 'web_url',
                              'title' => 'View More',
                              'url' => 'https://example.com/product1'
                            }
                          ]
                        }
                      ]
                    }
                  }
                }
              }
            ]
          }
        )
      end

      it 'detects socialwiseResponse in Dialogflow payload' do
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

        expect(Rails.logger).to have_received(:info).with(
          match(/socialwiseResponse detectado/)
        )
      end

      it 'extracts socialwiseResponse data correctly' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

        expected_socialwise_data = {
          'message_format' => 'GENERIC_TEMPLATE',
          'payload' => {
            'template_type' => 'generic',
            'elements' => [
              {
                'title' => 'Product 1',
                'subtitle' => 'Amazing product',
                'image_url' => 'https://example.com/image1.jpg',
                'buttons' => [
                  {
                    'type' => 'web_url',
                    'title' => 'View More',
                    'url' => 'https://example.com/product1'
                  }
                ]
              }
            ]
          }
        }

        expect(Integrations::Socialwise::InstagramResponseProcessor).to have_received(:process)
          .with(expected_socialwise_data, instagram_message)
      end

      it 'logs socialwiseResponse processing start' do
        allow(Rails.logger).to receive(:info)
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

        expect(Rails.logger).to have_received(:info).with(
          match(/\[SOCIALWISE-DIALOGFLOW-PRIMITIVE\] socialwiseResponse detectado:.*GENERIC_TEMPLATE/)
        )
      end

      it 'validates Instagram channel before processing' do
        allow(Rails.logger).to receive(:info)
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

        expect(Rails.logger).to have_received(:info).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Instagram channel validated, processing socialwiseResponse'
        )
      end
    end

    context 'when Dialogflow response does not contain socialwiseResponse' do
      let(:dialogflow_response_without_socialwise) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'text' => {
                  'text' => ['Hello, how can I help you?']
                }
              }
            ]
          }
        )
      end

      it 'does not detect socialwiseResponse' do
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_without_socialwise)

        expect(Rails.logger).not_to have_received(:info).with(
          match(/socialwiseResponse detectado/)
        )
      end

      it 'processes standard text message instead' do
        expect(instagram_conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Hello, how can I help you?',
            message_type: :outgoing
          )
        )
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_without_socialwise)
      end

      it 'logs standard conversation creation' do
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_without_socialwise)

        expect(Rails.logger).to have_received(:info).with(
          match(/Criando conversa com content_params/)
        )
      end
    end

    context 'when socialwiseResponse is present but empty' do
      let(:dialogflow_response_with_empty_socialwise) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'payload' => {
                  'socialwiseResponse' => nil
                }
              }
            ]
          }
        )
      end

      it 'does not process empty socialwiseResponse' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_empty_socialwise)

        expect(Integrations::Socialwise::InstagramResponseProcessor).not_to have_received(:process)
      end

      it 'continues with normal flow when socialwiseResponse is empty' do
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_empty_socialwise)

        expect(Rails.logger).not_to have_received(:info).with(
          match(/socialwiseResponse detectado/)
        )
      end
    end
  end

  describe 'priority rule implementation (socialwiseResponse over text messages)' do
    context 'when response contains both socialwiseResponse and text messages' do
      let(:dialogflow_response_with_both) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'text' => {
                  'text' => ['This text should be ignored']
                }
              },
              {
                'payload' => {
                  'socialwiseResponse' => {
                    'message_format' => 'BUTTON_TEMPLATE',
                    'payload' => {
                      'template_type' => 'button',
                      'text' => 'Choose an option:',
                      'buttons' => [
                        {
                          'type' => 'postback',
                          'title' => 'Yes',
                          'payload' => 'YES'
                        }
                      ]
                    }
                  }
                }
              },
              {
                'text' => {
                  'text' => ['This text should also be ignored']
                }
              }
            ]
          }
        )
      end

      it 'processes socialwiseResponse and skips text messages' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_both)

        expect(Integrations::Socialwise::InstagramResponseProcessor).to have_received(:process).once
        expect(Rails.logger).to have_received(:info).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse processado com sucesso, pulando mensagem normal'
        )
      end

      it 'does not create standard text messages when socialwiseResponse is processed' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        
        expect(instagram_conversation.messages).not_to receive(:create!)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_both)
      end

      it 'logs priority rule application' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_both)

        expect(Rails.logger).to have_received(:info).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse processado com sucesso, pulando mensagem normal'
        )
      end

      it 'breaks out of fulfillment_messages loop after processing socialwiseResponse' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_both)

        # Should only process the first two messages (text + socialwiseResponse), then break
        expect(Rails.logger).to have_received(:info).with(
          match(/Processando fulfillment_message\[0\]/)
        )
        expect(Rails.logger).to have_received(:info).with(
          match(/Processando fulfillment_message\[1\]/)
        )
        expect(Rails.logger).not_to have_received(:info).with(
          match(/Processando fulfillment_message\[2\]/)
        )
      end
    end

    context 'when socialwiseResponse processing fails' do
      let(:dialogflow_response_with_both) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'payload' => {
                  'socialwiseResponse' => {
                    'message_format' => 'INVALID_FORMAT',
                    'payload' => {}
                  }
                }
              },
              {
                'text' => {
                  'text' => ['Fallback text message']
                }
              }
            ]
          }
        )
      end

      it 'continues with normal flow when socialwiseResponse processing fails' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
        allow(Rails.logger).to receive(:warn)
        
        expect(instagram_conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Fallback text message',
            message_type: :outgoing
          )
        )
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_both)

        expect(Rails.logger).to have_received(:warn).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse falhou, continuando com fluxo normal'
        )
      end

      it 'processes subsequent messages when socialwiseResponse fails' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_both)

        expect(Rails.logger).to have_received(:info).with(
          match(/Criando conversa com content_params/)
        )
      end
    end
  end

  describe 'integration with SocialWise Instagram Response Processor' do
    let(:dialogflow_response_with_socialwise) do
      double(
        query_result: {
          'fulfillment_messages' => [
            {
              'payload' => {
                'socialwiseResponse' => {
                  'message_format' => 'QUICK_REPLIES',
                  'payload' => {
                    'text' => 'What would you like to do?',
                    'quick_replies' => [
                      {
                        'content_type' => 'text',
                        'title' => 'Option 1',
                        'payload' => 'OPTION_1'
                      },
                      {
                        'content_type' => 'text',
                        'title' => 'Option 2',
                        'payload' => 'OPTION_2'
                      }
                    ]
                  }
                }
              }
            }
          ]
        }
      )
    end

    it 'calls Instagram Response Processor with correct parameters' do
      expect(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).with(
        {
          'message_format' => 'QUICK_REPLIES',
          'payload' => {
            'text' => 'What would you like to do?',
            'quick_replies' => [
              {
                'content_type' => 'text',
                'title' => 'Option 1',
                'payload' => 'OPTION_1'
              },
              {
                'content_type' => 'text',
                'title' => 'Option 2',
                'payload' => 'OPTION_2'
              }
            ]
          }
        },
        instagram_message
      ).and_return(true)
      
      instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)
    end

    it 'handles Instagram Response Processor success' do
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
      allow(Rails.logger).to receive(:info)
      
      instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

      expect(Rails.logger).to have_received(:info).with(
        '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse processado com sucesso, pulando mensagem normal'
      )
    end

    it 'handles Instagram Response Processor failure' do
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
      allow(Rails.logger).to receive(:warn)
      
      instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

      expect(Rails.logger).to have_received(:warn).with(
        '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse falhou, continuando com fluxo normal'
      )
    end

    it 'handles Instagram Response Processor exceptions' do
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process)
        .and_raise(StandardError, 'Processing error')
      allow(Rails.logger).to receive(:error)
      
      instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

      expect(Rails.logger).to have_received(:error).with(
        match(/=== SOCIALWISE RESPONSE PROCESSING EXCEPTION ===/)
      )
      expect(Rails.logger).to have_received(:error).with(
        '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Exception class: StandardError'
      )
      expect(Rails.logger).to have_received(:error).with(
        '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Exception message: Processing error'
      )
    end

    it 'logs comprehensive context on exceptions' do
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process)
        .and_raise(StandardError, 'Processing error')
      allow(Rails.logger).to receive(:error)
      
      instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

      expect(Rails.logger).to have_received(:error).with(
        "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Message ID: #{instagram_message.id}"
      )
      expect(Rails.logger).to have_received(:error).with(
        "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Conversation ID: #{instagram_conversation.id}"
      )
      expect(Rails.logger).to have_received(:error).with(
        "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Account ID: #{account.id}"
      )
      expect(Rails.logger).to have_received(:error).with(
        "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Inbox ID: #{instagram_inbox.id}"
      )
      expect(Rails.logger).to have_received(:error).with(
        '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Channel type: Channel::Instagram'
      )
    end

    it 'returns false on Instagram Response Processor exceptions' do
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process)
        .and_raise(StandardError, 'Processing error')
      allow(Rails.logger).to receive(:error)
      
      result = instagram_service.send(:process_socialwise_response, 
                                     { 'message_format' => 'GENERIC_TEMPLATE' }, 
                                     instagram_message)

      expect(result).to be false
    end
  end

  describe 'existing Dialogflow functionality remains unaffected' do
    context 'when processing standard Dialogflow responses' do
      let(:standard_dialogflow_response) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'text' => {
                  'text' => ['Hello, how can I help you today?']
                }
              }
            ]
          }
        )
      end

      it 'processes standard text messages normally' do
        expect(instagram_conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Hello, how can I help you today?',
            message_type: :outgoing,
            account_id: account.id,
            inbox_id: instagram_inbox.id
          )
        )
        
        instagram_service.send(:process_response, instagram_message, standard_dialogflow_response)
      end

      it 'maintains existing logging for standard messages' do
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, standard_dialogflow_response)

        expect(Rails.logger).to have_received(:info).with(
          match(/Criando conversa com content_params/)
        )
      end

      it 'does not interfere with action processing' do
        action_response = double(
          query_result: {
            'fulfillment_messages' => [
              {
                'payload' => {
                  'action' => 'transfer_to_agent'
                }
              }
            ]
          }
        )

        expect(instagram_service).to receive(:process_action).with(instagram_message, 'transfer_to_agent')
        
        instagram_service.send(:process_response, instagram_message, action_response)
      end

      it 'maintains existing error handling for standard flow' do
        allow(instagram_conversation.messages).to receive(:create!).and_raise(StandardError, 'Database error')
        allow(Rails.logger).to receive(:error)
        
        expect { instagram_service.send(:process_response, instagram_message, standard_dialogflow_response) }
          .to raise_error(StandardError, 'Database error')
      end
    end

    context 'when processing responses with multiple standard messages' do
      let(:multiple_messages_response) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'text' => {
                  'text' => ['First message']
                }
              },
              {
                'text' => {
                  'text' => ['Second message']
                }
              },
              {
                'text' => {
                  'text' => ['Third message']
                }
              }
            ]
          }
        )
      end

      it 'processes all standard messages in sequence' do
        expect(instagram_conversation.messages).to receive(:create!).exactly(3).times
        
        instagram_service.send(:process_response, instagram_message, multiple_messages_response)
      end

      it 'logs processing for each message' do
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, multiple_messages_response)

        expect(Rails.logger).to have_received(:info).with(
          match(/Processando fulfillment_message\[0\]/)
        )
        expect(Rails.logger).to have_received(:info).with(
          match(/Processando fulfillment_message\[1\]/)
        )
        expect(Rails.logger).to have_received(:info).with(
          match(/Processando fulfillment_message\[2\]/)
        )
      end
    end

    context 'when using non-Instagram channels' do
      let(:dialogflow_response_with_socialwise) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'payload' => {
                  'socialwiseResponse' => {
                    'message_format' => 'GENERIC_TEMPLATE',
                    'payload' => {
                      'template_type' => 'generic',
                      'elements' => [{ 'title' => 'Test' }]
                    }
                  }
                }
              }
            ]
          }
        )
      end

      it 'skips socialwiseResponse processing for non-Instagram channels' do
        allow(Rails.logger).to receive(:info)
        
        whatsapp_service.send(:process_response, whatsapp_message, dialogflow_response_with_socialwise)

        expect(Rails.logger).to have_received(:info).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse only supported for Instagram channels, got: Channel::Whatsapp'
        )
        expect(Rails.logger).to have_received(:info).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Skipping socialwiseResponse processing, will continue with normal flow'
        )
      end

      it 'continues with normal flow for non-Instagram channels' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process)
        
        whatsapp_service.send(:process_response, whatsapp_message, dialogflow_response_with_socialwise)

        expect(Integrations::Socialwise::InstagramResponseProcessor).not_to have_received(:process)
      end

      it 'does not break existing functionality for other channels' do
        standard_response = double(
          query_result: {
            'fulfillment_messages' => [
              {
                'text' => {
                  'text' => ['Standard message for WhatsApp']
                }
              }
            ]
          }
        )

        expect(whatsapp_conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Standard message for WhatsApp',
            message_type: :outgoing
          )
        )
        
        whatsapp_service.send(:process_response, whatsapp_message, standard_response)
      end
    end
  end

  describe 'mixed scenarios (some messages with socialwiseResponse, others without)' do
    context 'when response has socialwiseResponse followed by standard messages' do
      let(:mixed_response_socialwise_first) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'payload' => {
                  'socialwiseResponse' => {
                    'message_format' => 'BUTTON_TEMPLATE',
                    'payload' => {
                      'template_type' => 'button',
                      'text' => 'Rich message',
                      'buttons' => [{ 'type' => 'postback', 'title' => 'OK', 'payload' => 'OK' }]
                    }
                  }
                }
              },
              {
                'text' => {
                  'text' => ['This should be ignored due to priority rule']
                }
              }
            ]
          }
        )
      end

      it 'processes socialwiseResponse and skips subsequent messages' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        
        expect(instagram_conversation.messages).not_to receive(:create!)
        
        instagram_service.send(:process_response, instagram_message, mixed_response_socialwise_first)
      end

      it 'logs priority rule enforcement' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, mixed_response_socialwise_first)

        expect(Rails.logger).to have_received(:info).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse processado com sucesso, pulando mensagem normal'
        )
      end
    end

    context 'when response has standard messages followed by socialwiseResponse' do
      let(:mixed_response_socialwise_last) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'text' => {
                  'text' => ['First standard message']
                }
              },
              {
                'payload' => {
                  'socialwiseResponse' => {
                    'message_format' => 'QUICK_REPLIES',
                    'payload' => {
                      'text' => 'Choose option:',
                      'quick_replies' => [{ 'content_type' => 'text', 'title' => 'Yes', 'payload' => 'YES' }]
                    }
                  }
                }
              },
              {
                'text' => {
                  'text' => ['This should be ignored']
                }
              }
            ]
          }
        )
      end

      it 'processes first standard message, then socialwiseResponse, then stops' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        
        expect(instagram_conversation.messages).to receive(:create!).once.with(
          hash_including(
            content: 'First standard message',
            message_type: :outgoing
          )
        )
        
        instagram_service.send(:process_response, instagram_message, mixed_response_socialwise_last)
      end

      it 'logs processing of both message types' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, mixed_response_socialwise_last)

        expect(Rails.logger).to have_received(:info).with(
          match(/Criando conversa com content_params/)
        )
        expect(Rails.logger).to have_received(:info).with(
          match(/socialwiseResponse detectado/)
        )
        expect(Rails.logger).to have_received(:info).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse processado com sucesso, pulando mensagem normal'
        )
      end
    end

    context 'when response has multiple socialwiseResponse entries' do
      let(:multiple_socialwise_response) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'payload' => {
                  'socialwiseResponse' => {
                    'message_format' => 'GENERIC_TEMPLATE',
                    'payload' => {
                      'template_type' => 'generic',
                      'elements' => [{ 'title' => 'First rich message' }]
                    }
                  }
                }
              },
              {
                'payload' => {
                  'socialwiseResponse' => {
                    'message_format' => 'BUTTON_TEMPLATE',
                    'payload' => {
                      'template_type' => 'button',
                      'text' => 'Second rich message',
                      'buttons' => [{ 'type' => 'postback', 'title' => 'OK', 'payload' => 'OK' }]
                    }
                  }
                }
              }
            ]
          }
        )
      end

      it 'processes only the first socialwiseResponse due to priority rule' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        
        instagram_service.send(:process_response, instagram_message, multiple_socialwise_response)

        expect(Integrations::Socialwise::InstagramResponseProcessor).to have_received(:process).once
      end

      it 'logs processing of first socialwiseResponse only' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, multiple_socialwise_response)

        expect(Rails.logger).to have_received(:info).with(
          match(/socialwiseResponse detectado.*GENERIC_TEMPLATE/)
        )
        expect(Rails.logger).not_to have_received(:info).with(
          match(/socialwiseResponse detectado.*BUTTON_TEMPLATE/)
        )
      end
    end

    context 'when socialwiseResponse processing fails in mixed scenario' do
      let(:mixed_response_with_fallback) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'payload' => {
                  'socialwiseResponse' => {
                    'message_format' => 'INVALID_FORMAT',
                    'payload' => {}
                  }
                }
              },
              {
                'text' => {
                  'text' => ['Fallback message after failed rich message']
                }
              }
            ]
          }
        )
      end

      it 'continues processing subsequent messages when socialwiseResponse fails' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
        
        expect(instagram_conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Fallback message after failed rich message',
            message_type: :outgoing
          )
        )
        
        instagram_service.send(:process_response, instagram_message, mixed_response_with_fallback)
      end

      it 'logs failure and continuation' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, mixed_response_with_fallback)

        expect(Rails.logger).to have_received(:warn).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse falhou, continuando com fluxo normal'
        )
        expect(Rails.logger).to have_received(:info).with(
          match(/Criando conversa com content_params/)
        )
      end
    end
  end

  describe 'error handling when rich message processing fails' do
    let(:dialogflow_response_with_socialwise) do
      double(
        query_result: {
          'fulfillment_messages' => [
            {
              'payload' => {
                'socialwiseResponse' => {
                  'message_format' => 'GENERIC_TEMPLATE',
                  'payload' => {
                    'template_type' => 'generic',
                    'elements' => [{ 'title' => 'Test' }]
                  }
                }
              }
            }
          ]
        }
      )
    end

    context 'when Instagram Response Processor raises an exception' do
      it 'catches and logs the exception' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process)
          .and_raise(StandardError, 'Instagram API error')
        allow(Rails.logger).to receive(:error)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

        expect(Rails.logger).to have_received(:error).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Exception class: StandardError'
        )
        expect(Rails.logger).to have_received(:error).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Exception message: Instagram API error'
        )
      end

      it 'logs comprehensive error context' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process)
          .and_raise(StandardError, 'Instagram API error')
        allow(Rails.logger).to receive(:error)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

        expect(Rails.logger).to have_received(:error).with(
          "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Message ID: #{instagram_message.id}"
        )
        expect(Rails.logger).to have_received(:error).with(
          "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Conversation ID: #{instagram_conversation.id}"
        )
        expect(Rails.logger).to have_received(:error).with(
          "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Account ID: #{account.id}"
        )
        expect(Rails.logger).to have_received(:error).with(
          "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Inbox ID: #{instagram_inbox.id}"
        )
        expect(Rails.logger).to have_received(:error).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Channel type: Channel::Instagram'
        )
      end

      it 'logs the socialwiseResponse data that caused the error' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process)
          .and_raise(StandardError, 'Instagram API error')
        allow(Rails.logger).to receive(:error)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

        expect(Rails.logger).to have_received(:error).with(
          match(/SocialWise data:.*GENERIC_TEMPLATE/)
        )
      end

      it 'logs the full backtrace for debugging' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process)
          .and_raise(StandardError, 'Instagram API error')
        allow(Rails.logger).to receive(:error)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

        expect(Rails.logger).to have_received(:error).with(
          match(/Backtrace:/)
        )
      end

      it 'indicates fallback to normal flow' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process)
          .and_raise(StandardError, 'Instagram API error')
        allow(Rails.logger).to receive(:error)
        allow(Rails.logger).to receive(:info)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

        expect(Rails.logger).to have_received(:info).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Will fallback to normal flow due to exception'
        )
      end

      it 'returns false from process_socialwise_response on exception' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process)
          .and_raise(StandardError, 'Instagram API error')
        allow(Rails.logger).to receive(:error)
        
        result = instagram_service.send(:process_socialwise_response, 
                                       { 'message_format' => 'GENERIC_TEMPLATE' }, 
                                       instagram_message)

        expect(result).to be false
      end
    end

    context 'when Instagram Response Processor returns false' do
      it 'logs processing failure' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
        allow(Rails.logger).to receive(:warn)
        
        instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

        expect(Rails.logger).to have_received(:warn).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse processing failed, will fallback to normal flow'
        )
      end

      it 'continues with normal message processing' do
        response_with_fallback = double(
          query_result: {
            'fulfillment_messages' => [
              {
                'payload' => {
                  'socialwiseResponse' => {
                    'message_format' => 'INVALID_FORMAT',
                    'payload' => {}
                  }
                }
              },
              {
                'text' => {
                  'text' => ['Fallback text message']
                }
              }
            ]
          }
        )

        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
        
        expect(instagram_conversation.messages).to receive(:create!).with(
          hash_including(
            content: 'Fallback text message',
            message_type: :outgoing
          )
        )
        
        instagram_service.send(:process_response, instagram_message, response_with_fallback)
      end
    end

    context 'when channel validation fails' do
      it 'logs channel validation failure for non-Instagram channels' do
        allow(Rails.logger).to receive(:info)
        
        whatsapp_service.send(:process_socialwise_response, 
                             { 'message_format' => 'GENERIC_TEMPLATE' }, 
                             whatsapp_message)

        expect(Rails.logger).to have_received(:info).with(
          '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] socialwiseResponse only supported for Instagram channels, got: Channel::Whatsapp'
        )
      end

      it 'returns false for non-Instagram channels' do
        result = whatsapp_service.send(:process_socialwise_response, 
                                      { 'message_format' => 'GENERIC_TEMPLATE' }, 
                                      whatsapp_message)

        expect(result).to be false
      end

      it 'does not call Instagram Response Processor for non-Instagram channels' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process)
        
        whatsapp_service.send(:process_socialwise_response, 
                             { 'message_format' => 'GENERIC_TEMPLATE' }, 
                             whatsapp_message)

        expect(Integrations::Socialwise::InstagramResponseProcessor).not_to have_received(:process)
      end
    end

    context 'when error recovery mechanisms are tested' do
      let(:response_with_multiple_fallbacks) do
        double(
          query_result: {
            'fulfillment_messages' => [
              {
                'payload' => {
                  'socialwiseResponse' => {
                    'message_format' => 'INVALID_FORMAT',
                    'payload' => {}
                  }
                }
              },
              {
                'text' => {
                  'text' => ['First fallback message']
                }
              },
              {
                'text' => {
                  'text' => ['Second fallback message']
                }
              }
            ]
          }
        )
      end

      it 'processes all fallback messages when socialwiseResponse fails' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
        
        expect(instagram_conversation.messages).to receive(:create!).twice
        
        instagram_service.send(:process_response, instagram_message, response_with_multiple_fallbacks)
      end

      it 'maintains message order in fallback scenario' do
        allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
        
        expect(instagram_conversation.messages).to receive(:create!).with(
          hash_including(content: 'First fallback message')
        ).ordered
        expect(instagram_conversation.messages).to receive(:create!).with(
          hash_including(content: 'Second fallback message')
        ).ordered
        
        instagram_service.send(:process_response, instagram_message, response_with_multiple_fallbacks)
      end
    end
  end

  describe 'performance and logging verification' do
    let(:dialogflow_response_with_socialwise) do
      double(
        query_result: {
          'fulfillment_messages' => [
            {
              'payload' => {
                'socialwiseResponse' => {
                  'message_format' => 'GENERIC_TEMPLATE',
                  'payload' => {
                    'template_type' => 'generic',
                    'elements' => [{ 'title' => 'Performance test' }]
                  }
                }
              }
            }
          ]
        }
      )
    end

    it 'logs processing start and completion' do
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
      allow(Rails.logger).to receive(:info)
      
      instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

      expect(Rails.logger).to have_received(:info).with(
        '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] === INICIANDO PROCESSAMENTO DA RESPOSTA DO DIALOGFLOW ==='
      )
      expect(Rails.logger).to have_received(:info).with(
        '[SOCIALWISE-DIALOGFLOW-PRIMITIVE] === FINALIZANDO PROCESSAMENTO DA RESPOSTA DO DIALOGFLOW ==='
      )
    end

    it 'logs message and conversation context' do
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
      allow(Rails.logger).to receive(:info)
      
      instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

      expect(Rails.logger).to have_received(:info).with(
        "[SOCIALWISE-DIALOGFLOW-PRIMITIVE] Message ID: #{instagram_message.id}, Conversation ID: #{instagram_conversation.id}"
      )
    end

    it 'logs Dialogflow response structure for debugging' do
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
      allow(Rails.logger).to receive(:info)
      
      instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)

      expect(Rails.logger).to have_received(:info).with(
        match(/Resposta RAW do Dialogflow/)
      )
      expect(Rails.logger).to have_received(:info).with(
        match(/QUERY RESULT COMPLETO EM HASH/)
      )
    end

    it 'completes processing within reasonable time' do
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
      
      start_time = Time.current
      instagram_service.send(:process_response, instagram_message, dialogflow_response_with_socialwise)
      elapsed_time = Time.current - start_time

      expect(elapsed_time).to be < 1.0 # Should complete within 1 second
    end
  end
end