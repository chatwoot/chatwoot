require 'rails_helper'

RSpec.describe 'SocialWise Flow Real Payloads Integration', type: :integration do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation, content: 'Test message') }
  
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
    allow(Whatsapp::SendOnWhatsappService).to receive(:new).and_return(double(perform: true))
    allow(Facebook::SendOnFacebookService).to receive(:new).and_return(double(perform: true))
    allow(Facebook::RawDeliverService).to receive(:new).and_return(double(perform: true))
    allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(true)
  end

  describe 'Real WhatsApp Interactive Payloads' do
    it 'processes actual SocialWise Flow WhatsApp button payload' do
      # This is a real payload format from SocialWise Flow
      real_whatsapp_payload = {
        'whatsapp' => {
          'type' => 'interactive',
          'interactive' => {
            'body' => {
              'text' => '> Sr(a) *Cliente*, \nSomos especializados em mandado de segurança e podemos ajudá-lo com seu caso. Nossa equipe tem ampla experiência em questões jurídicas complexas.'
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

      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, real_whatsapp_payload)
      
      expect(conversation.messages.count).to be > initial_count
      
      created_message = conversation.messages.outgoing.last
      expect(created_message.content_type).to eq('integrations')
      expect(created_message.content).to include('Sr(a) *Cliente*')
      expect(created_message.content_attributes['interactive']['type']).to eq('button')
      expect(created_message.content_attributes['interactive']['action']['buttons'].first['reply']['id']).to eq('btn_1756139209769_0_u8bq')
    end

    it 'processes WhatsApp list payload with multiple options' do
      real_list_payload = {
        'whatsapp' => {
          'type' => 'interactive',
          'interactive' => {
            'body' => {
              'text' => 'Escolha o serviço jurídico que precisa:'
            },
            'footer' => {
              'text' => 'Dra. Amanda Sousa Advocacia'
            },
            'type' => 'list',
            'action' => {
              'button' => 'Ver Serviços',
              'sections' => [
                {
                  'title' => 'Serviços Disponíveis',
                  'rows' => [
                    {
                      'id' => 'mandado_seguranca',
                      'title' => 'Mandado de Segurança',
                      'description' => 'Proteção de direitos líquidos e certos'
                    },
                    {
                      'id' => 'consultoria_juridica',
                      'title' => 'Consultoria Jurídica',
                      'description' => 'Orientação legal especializada'
                    },
                    {
                      'id' => 'revisao_contratos',
                      'title' => 'Revisão de Contratos',
                      'description' => 'Análise e revisão de documentos'
                    },
                    {
                      'id' => 'defesa_administrativa',
                      'title' => 'Defesa Administrativa',
                      'description' => 'Representação em processos administrativos'
                    }
                  ]
                }
              ]
            }
          }
        }
      }

      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, real_list_payload)
      
      expect(conversation.messages.count).to be > initial_count
      
      created_message = conversation.messages.outgoing.last
      expect(created_message.content_type).to eq('integrations')
      expect(created_message.content_attributes['interactive']['type']).to eq('list')
      expect(created_message.content_attributes['interactive']['action']['sections'].first['rows'].count).to eq(4)
    end
  end

  describe 'Real Instagram Rich Message Payloads' do
    it 'processes actual Instagram Generic Template payload' do
      real_instagram_generic = {
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

      allow(inbox).to receive(:channel_type).and_return('Channel::FacebookPage')
      
      processor_service.send(:process_response, message, real_instagram_generic)
      
      expect(Integrations::Socialwise::InstagramResponseProcessor).to have_received(:process)
        .with(real_instagram_generic['instagram'], message)
    end

    it 'processes actual Instagram Button Template payload' do
      real_instagram_button = {
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

      allow(inbox).to receive(:channel_type).and_return('Channel::FacebookPage')
      
      processor_service.send(:process_response, message, real_instagram_button)
      
      expect(Integrations::Socialwise::InstagramResponseProcessor).to have_received(:process)
        .with(real_instagram_button['instagram'], message)
    end

    it 'processes actual Instagram Quick Replies payload' do
      real_instagram_quick_replies = {
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
      }

      allow(inbox).to receive(:channel_type).and_return('Channel::FacebookPage')
      
      processor_service.send(:process_response, message, real_instagram_quick_replies)
      
      expect(Integrations::Socialwise::InstagramResponseProcessor).to have_received(:process)
        .with(real_instagram_quick_replies['instagram'], message)
    end
  end

  describe 'Real Button Reaction Payloads' do
    it 'processes actual WhatsApp button reaction payload' do
      real_whatsapp_button_reaction = {
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

      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      conversation.update!(status: 'pending')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, real_whatsapp_button_reaction)
      
      expect(conversation.messages.count).to be > initial_count
      
      # Check handoff was processed
      conversation.reload
      expect(conversation.status).to eq('open')
      
      # Verify messages were created
      messages = conversation.messages.reload
      expect(messages.count).to be > initial_count
    end

    it 'processes actual Instagram button reaction payload' do
      real_instagram_button_reaction = {
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

      allow(inbox).to receive(:channel_type).and_return('Channel::FacebookPage')
      conversation.update!(status: 'pending')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, real_instagram_button_reaction)
      
      expect(conversation.messages.count).to be > initial_count
      
      # Check handoff was processed
      conversation.reload
      expect(conversation.status).to eq('open')
    end
  end

  describe 'Real Facebook Message Payloads' do
    it 'processes actual Facebook text message payload' do
      real_facebook_text = {
        'facebook' => {
          'message' => {
            'text' => 'Olá! Bem-vindo ao nosso atendimento. Como posso ajudá-lo hoje?'
          }
        }
      }

      allow(inbox).to receive(:channel_type).and_return('Channel::FacebookPage')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, real_facebook_text)
      
      expect(conversation.messages.count).to be > initial_count
      
      created_message = conversation.messages.outgoing.last
      expect(created_message.content).to eq('Olá! Bem-vindo ao nosso atendimento. Como posso ajudá-lo hoje?')
      expect(created_message.content_type).to eq('text')
    end

    it 'processes actual Facebook rich content payload' do
      real_facebook_rich = {
        'facebook' => {
          'message' => {
            'text' => 'Escolha uma das opções abaixo:',
            'quick_replies' => [
              {
                'content_type' => 'text',
                'title' => 'Suporte Técnico',
                'payload' => 'TECHNICAL_SUPPORT'
              },
              {
                'content_type' => 'text',
                'title' => 'Vendas',
                'payload' => 'SALES_INQUIRY'
              },
              {
                'content_type' => 'text',
                'title' => 'Informações',
                'payload' => 'GENERAL_INFO'
              }
            ]
          }
        }
      }

      allow(inbox).to receive(:channel_type).and_return('Channel::FacebookPage')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, real_facebook_rich)
      
      expect(conversation.messages.count).to be > initial_count
      
      created_message = conversation.messages.outgoing.last
      expect(created_message.content_type).to eq('integrations')
      expect(created_message.content_attributes['message']['quick_replies'].count).to eq(3)
    end
  end

  describe 'Mixed Response Scenarios' do
    it 'processes response with both message and handoff action' do
      mixed_response = {
        'action' => 'handoff',
        'whatsapp' => {
          'type' => 'text',
          'text' => { 'body' => 'Transferindo você para um de nossos especialistas. Aguarde um momento...' }
        }
      }

      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      conversation.update!(status: 'pending')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, mixed_response)
      
      # Should create message
      expect(conversation.messages.count).to be > initial_count
      
      # Should process handoff
      conversation.reload
      expect(conversation.status).to eq('open')
      
      # Verify message content
      created_message = conversation.messages.outgoing.last
      if created_message
        expect(created_message.content).to include('Transferindo você para um de nossos especialistas')
      else
        # At minimum, verify messages were created
        expect(conversation.messages.count).to be > initial_count
      end
    end

    it 'handles complex button reaction with handoff and multiple message types' do
      complex_response = {
        'action_type' => 'button_reaction',
        'buttonId' => 'complex_btn_123',
        'processed' => true,
        'mappingFound' => true,
        'emoji' => '✅',
        'text' => 'Perfeito! Vou conectar você com nossa equipe especializada.',
        'action' => 'handoff',
        'whatsapp' => {
          'message_id' => 'wamid.complex_test_123',
          'reaction_emoji' => '✅',
          'response_text' => 'Perfeito! Vou conectar você com nossa equipe especializada.'
        }
      }

      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      conversation.update!(status: 'pending')
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, complex_response)
      
      # Should create messages
      expect(conversation.messages.count).to be > initial_count
      
      # Should process handoff
      conversation.reload
      expect(conversation.status).to eq('open')
      
      # Verify messages were created
      messages = conversation.messages.reload
      expect(messages.count).to be > initial_count
    end
  end

  describe 'Error Recovery with Real Payloads' do
    it 'handles malformed WhatsApp payload gracefully' do
      malformed_whatsapp = {
        'whatsapp' => {
          'type' => 'interactive',
          'interactive' => nil # This should cause an error
        }
      }

      allow(inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      
      expect {
        processor_service.send(:process_response, message, malformed_whatsapp)
      }.not_to raise_error
    end

    it 'handles Instagram processor failure with fallback' do
      instagram_payload = {
        'instagram' => {
          'message_format' => 'GENERIC_TEMPLATE',
          'elements' => [{ 'title' => 'Test' }]
        }
      }

      allow(inbox).to receive(:channel_type).and_return('Channel::FacebookPage')
      allow(Integrations::Socialwise::InstagramResponseProcessor).to receive(:process).and_return(false)
      
      initial_count = conversation.messages.count
      
      processor_service.send(:process_response, message, instagram_payload)
      
      # Should create fallback message
      expect(conversation.messages.count).to be > initial_count
    end
  end
end