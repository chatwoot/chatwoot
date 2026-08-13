require 'rails_helper'

describe Whatsapp::IncomingMessageAvisaService do
  before { allow(ENV).to receive(:[]).and_call_original }

  let!(:avisa_channel) do
    allow(ENV).to receive(:[]).with('FRONTEND_URL').and_return('https://chat.test')
    create(:channel_whatsapp, provider: 'avisa',
                              provider_config: {
                                'api_key' => 'avisa_token',
                                'base_url' => 'https://avisa.test',
                                'skip_avisa_webhook_setup' => true
                              },
                              sync_templates: false, validate_provider_config: false)
  end
  let(:inbox) { avisa_channel.inbox }
  let(:phone_jid) { '5534999990000@s.whatsapp.net' }

  def json_data(message)
    {
      'event' => {
        'Info' => { 'ID' => 'SRC123', 'Chat' => phone_jid, 'PushName' => 'Cliente', 'IsFromMe' => false },
        'Message' => message
      }
    }.to_json
  end

  def file_param
    Rack::Test::UploadedFile.new(Rails.root.join('spec/assets/avatar.png'), 'image/png')
  end

  describe '#perform' do
    context 'when a text message arrives' do
      it 'creates a conversation with a visible message' do
        params = { jsonData: json_data('conversation' => 'Olá') }
        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.conversations.count).to eq(1)
        expect(inbox.messages.count).to eq(1)
        expect(inbox.messages.first.content).to eq('Olá')
      end
    end

    context 'when the real message is wrapped in an envelope (ephemeral/view-once)' do
      it 'unwraps the inner text instead of showing "[mensagem não suportada]"' do
        params = {
          jsonData: json_data(
            'ephemeralMessage' => { 'message' => { 'conversation' => 'Oi temporária' } }
          ),
        }
        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.messages.last.content).to eq('Oi temporária')
      end

      it 'unwraps nested envelopes (view-once dentro de ephemeral)' do
        params = {
          jsonData: json_data(
            'ephemeralMessage' => {
              'message' => {
                'viewOnceMessageV2' => {
                  'message' => { 'extendedTextMessage' => { 'text' => 'Oi nested' } },
                },
              },
            }
          ),
        }
        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.messages.last.content).to eq('Oi nested')
      end
    end

    context 'when the real message is wrapped in associatedChild/deviceSent envelope' do
      it 'unwraps associatedChildMessage (FutureProof) — não vira placeholder' do
        params = {
          jsonData: json_data(
            'associatedChildMessage' => { 'message' => { 'conversation' => 'Oi child' } },
          ),
        }
        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.messages.last.content).to eq('Oi child')
      end

      it 'unwraps deviceSentMessage (envio de dispositivo vinculado)' do
        params = {
          jsonData: json_data(
            'deviceSentMessage' => { 'message' => { 'conversation' => 'Oi device' } },
          ),
        }
        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.messages.last.content).to eq('Oi device')
      end
    end

    context 'when a button/list reply arrives (template/carrossel)' do
      it 'usa o rótulo escolhido como texto da mensagem' do
        params = {
          jsonData: json_data(
            'templateButtonReplyMessage' => { 'selectedDisplayText' => 'Quero Falar Sobre' },
          ),
        }
        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.messages.last.content).to eq('Quero Falar Sobre')
      end

      it 'captura o id do botão (veiculo:<id>) em content_attributes (TRIGGER #15)' do
        params = {
          jsonData: json_data(
            'templateButtonReplyMessage' => {
              'selectedDisplayText' => 'Quero Falar Sobre',
              'selectedId' => 'veiculo:abc-123',
            },
          ),
        }
        described_class.new(inbox: inbox, params: params).perform

        msg = inbox.messages.last
        expect(msg.content).to eq('Quero Falar Sobre')
        expect(msg.content_attributes['button_payload']).to eq('veiculo:abc-123')
        expect(msg.content_attributes['button_title']).to eq('Quero Falar Sobre')
      end

      it 'também cobre buttonsResponseMessage.selectedButtonId' do
        params = {
          jsonData: json_data(
            'buttonsResponseMessage' => {
              'selectedDisplayText' => 'Quero Falar Sobre',
              'selectedButtonId' => 'veiculo:def-456',
            },
          ),
        }
        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.messages.last.content_attributes['button_payload']).to eq('veiculo:def-456')
      end
    end

    context 'when a structured type arrives (location/contact/poll)' do
      it 'renders a visible summary for location instead of "[mensagem não suportada]"' do
        params = {
          jsonData: json_data(
            'locationMessage' => { 'degreesLatitude' => -18.9, 'degreesLongitude' => -48.2 },
          ),
        }
        described_class.new(inbox: inbox, params: params).perform

        msg = inbox.messages.last
        expect(msg.content).to include('[localização]')
        expect(msg.content).to include('maps.google.com/?q=-18.9,-48.2')
        expect(msg.content_attributes['unsupported']).to be_nil
      end

      it 'renders a visible summary for a shared contact' do
        params = { jsonData: json_data('contactMessage' => { 'displayName' => 'João Silva' }) }
        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.messages.last.content).to eq('[contato] João Silva')
      end

      it 'renders a visible summary for a poll' do
        params = {
          jsonData: json_data(
            'pollCreationMessage' => {
              'name' => 'Qual cor?',
              'options' => [{ 'optionName' => 'Preto' }, { 'optionName' => 'Branco' }],
            },
          ),
        }
        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.messages.last.content).to eq('[enquete] Qual cor? — opções: Preto, Branco')
      end
    end

    context 'when a system protocolMessage (revoke/sync, não-edição) arrives' do
      it 'ignora silenciosamente — não cria placeholder' do
        params = { jsonData: json_data('protocolMessage' => { 'type' => 'REVOKE' }) }

        expect { described_class.new(inbox: inbox, params: params).perform }
          .not_to(change { inbox.messages.count })
      end
    end

    context 'when an albumMessage (cabeçalho de álbum) arrives' do
      it 'ignora silenciosamente — não cria placeholder (as fotos vêm separadas)' do
        params = { jsonData: json_data('albumMessage' => { 'expectedImageCount' => 2 }) }

        expect { described_class.new(inbox: inbox, params: params).perform }
          .not_to(change { inbox.messages.count })
      end
    end

    context 'when media attachment processing fails' do
      it 'still creates the message with a per-type fallback + media_error and logs the failure' do
        params = { jsonData: json_data('imageMessage' => { 'caption' => '' }), file: file_param }

        allow_any_instance_of(described_class).to receive(:attach_media).and_raise(StandardError, 'boom')
        expect(Rails.logger).to receive(:error).with(/\[AVISA\] attach_media failed/).at_least(:once)

        expect { described_class.new(inbox: inbox, params: params).perform }
          .to change { inbox.messages.count }.by(1)

        message = inbox.messages.last
        expect(message.attachments).to be_empty
        expect(message.content).to eq('[imagem recebida — não pôde ser processada]')
        expect(message.content_attributes['media_error']).to include('StandardError: boom')
      end
    end

    context 'when media is announced but the file payload is missing AND download fails' do
      it 'creates a fallback message with media_error instead of dropping it' do
        params = { jsonData: json_data('audioMessage' => {}) }
        allow_any_instance_of(Whatsapp::Providers::AvisaClient)
          .to receive(:download_audio).and_return(nil)

        expect { described_class.new(inbox: inbox, params: params).perform }
          .to change { inbox.messages.count }.by(1)

        message = inbox.messages.last
        expect(message.content).to eq('[áudio recebido — não pôde ser processado]')
        expect(message.content_attributes['media_error']).to be_present
      end
    end

    context 'when the message has no content and no attachment (unknown type)' do
      it 'persists a placeholder message flagged unsupported so the bubble renders' do
        params = { jsonData: json_data('someUnknownMessage' => { 'foo' => 'bar' }) }

        expect { described_class.new(inbox: inbox, params: params).perform }
          .to change { inbox.messages.count }.by(1)

        message = inbox.messages.last
        expect(message.content).to eq('[mensagem não suportada]')
        expect(message.content_attributes['unsupported']).to be(true)
      end
    end

    context 'when media is NOT inline but can be downloaded from Avisa' do
      it 'baixa o áudio (ptt/voice) decriptado e anexa em vez de placeholder' do
        params = { jsonData: json_data('audioMessage' => { 'mimetype' => 'audio/ogg; codecs=opus' }) }
        allow_any_instance_of(Whatsapp::Providers::AvisaClient)
          .to receive(:download_audio).and_return('OggS-fake-audio-bytes')

        described_class.new(inbox: inbox, params: params).perform

        att = inbox.messages.last.attachments.first
        expect(att).to be_present
        expect(att.file_type).to eq('audio')
      end

      it 'baixa a figurinha (nunca vem inline) e anexa' do
        params = { jsonData: json_data('stickerMessage' => { 'mimetype' => 'image/webp' }) }
        allow_any_instance_of(Whatsapp::Providers::AvisaClient)
          .to receive(:download_media).and_return('RIFF-fake-webp-bytes')

        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.messages.last.attachments.first).to be_present
      end
    end

    context 'when the lead comes from a Click-to-WhatsApp ad (anúncio FB/IG)' do
      def ad_message(text:, source_url:, media_url: nil)
        {
          'extendedTextMessage' => {
            'text' => text,
            'contextInfo' => {
              'externalAdReply' => {
                'title' => 'Cadillac Escalade | Estoque de Oportunidades',
                'sourceUrl' => source_url,
                'mediaUrl' => media_url,
                'thumbnailUrl' => 'https://scontent.xx.fbcdn.net/ad.jpg',
                'thumbnail' => 'BASE64THUMB'
              },
            },
          },
        }
      end

      it 'captura is_ad + ad_data e infere Facebook pela URL' do
        params = { jsonData: json_data(ad_message(text: 'Olá! Tenho interesse', source_url: 'https://fb.me/5VBu1YOSg')) }
        described_class.new(inbox: inbox, params: params).perform

        msg = inbox.messages.last
        expect(msg.content).to eq('Olá! Tenho interesse')
        attrs = msg.reload.content_attributes
        expect(attrs['is_ad']).to be(true)
        expect(attrs['ad_data']['title']).to eq('Cadillac Escalade | Estoque de Oportunidades')
        expect(attrs['ad_data']['source_app']).to eq('facebook')
        expect(attrs['ad_data']['source_url']).to eq('https://fb.me/5VBu1YOSg')
        expect(attrs['ad_data']['thumbnail_data']).to eq('BASE64THUMB')
      end

      it 'infere Instagram pela media_url' do
        params = { jsonData: json_data(ad_message(text: 'oi', source_url: 'https://wa.me/x', media_url: 'https://www.instagram.com/reel/abc/')) }
        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.messages.last.reload.content_attributes['ad_data']['source_app']).to eq('instagram')
      end

      it 'usa o cabeçalho do anúncio como content quando o cliente não manda texto' do
        params = { jsonData: json_data(ad_message(text: '', source_url: 'https://fb.me/5VBu1YOSg')) }
        described_class.new(inbox: inbox, params: params).perform

        msg = inbox.messages.last
        expect(msg.content).to include('Anúncio')
        expect(msg.content).to include('Cadillac Escalade')
        expect(msg.reload.content_attributes['is_ad']).to be(true)
      end
    end

    context 'when the client replies to a STATUS (caso conv 3769, 13/ago)' do
      # Payload REAL do caso: o WhatsApp anexa no contextInfo o quote do
      # Status (status@broadcast, com a legenda do carro postado) E TAMBÉM o
      # externalAdReply da ORIGEM antiga da thread (CTWA de meses atrás). O
      # assunto é o Status citado — o anúncio velho não pode ser carimbado.
      def status_reply_message(text: 'Valor')
        {
          'extendedTextMessage' => {
            'text' => text,
            'contextInfo' => {
              'stanzaID' => '3EB09E844C758E3A52814B',
              'participant' => '90649730801791@lid',
              'remoteJID' => 'status@broadcast',
              'quotedType' => 0,
              'entryPointConversionSource' => 'status',
              'quotedMessage' => {
                'imageMessage' => {
                  'URL' => 'https://mmg.whatsapp.net/foo',
                  'mimetype' => 'image/jpeg',
                  'caption' => '*Porsche Macan* | *2023* | 9.620km | Cor Azul Gentian'
                },
              },
              'externalAdReply' => {
                'title' => 'MERCEDES G-63  AMG ED1 4MATIC V8 Bi-TB [2019]',
                'sourceUrl' => 'https://www.instagram.com/p/DbiTYTNsyID/',
                'thumbnailUrl' => 'https://scontent.xx.fbcdn.net/old.jpg'
              },
            },
          },
        }
      end

      it 'preserva a legenda do Status e NÃO carimba o anúncio antigo' do
        params = { jsonData: json_data(status_reply_message) }
        described_class.new(inbox: inbox, params: params).perform

        msg = inbox.messages.last
        expect(msg.content).to eq('Valor')
        attrs = msg.reload.content_attributes
        expect(attrs['status_reply']).to be(true)
        expect(attrs['quoted_status_caption']).to include('Porsche Macan')
        expect(attrs['is_ad']).to be_nil
        expect(attrs['ad_data']).to be_nil
      end

      it 'sem legenda no quote, marca só o status_reply (sem chute)' do
        m = status_reply_message
        m['extendedTextMessage']['contextInfo']['quotedMessage'] = {
          'imageMessage' => { 'URL' => 'https://mmg.whatsapp.net/foo', 'mimetype' => 'image/jpeg' },
        }
        params = { jsonData: json_data(m) }
        described_class.new(inbox: inbox, params: params).perform

        attrs = inbox.messages.last.reload.content_attributes
        expect(attrs['status_reply']).to be(true)
        expect(attrs).not_to have_key('quoted_status_caption')
        expect(attrs['is_ad']).to be_nil
      end

      it 'CTWA legítimo (sem quote de status) segue carimbando o anúncio' do
        m = {
          'extendedTextMessage' => {
            'text' => 'Tenho interesse',
            'contextInfo' => {
              'externalAdReply' => {
                'title' => 'Cadillac Escalade | Estoque de Oportunidades',
                'sourceUrl' => 'https://fb.me/5VBu1YOSg'
              },
            },
          },
        }
        params = { jsonData: json_data(m) }
        described_class.new(inbox: inbox, params: params).perform

        attrs = inbox.messages.last.reload.content_attributes
        expect(attrs['is_ad']).to be(true)
        expect(attrs['status_reply']).to be_nil
      end
    end

    context 'when a templateMessage (HSM) arrives' do
      it 'extrai o corpo do hydratedTemplate em vez de "[mensagem não suportada]"' do
        params = {
          jsonData: json_data(
            'templateMessage' => {
              'hydratedTemplate' => {
                'hydratedTitle' => 'Promoção',
                'hydratedContentText' => 'Confira nossas ofertas de SUV',
                'hydratedFooterText' => 'Attra Veículos',
              },
            },
          ),
        }
        described_class.new(inbox: inbox, params: params).perform

        msg = inbox.messages.last
        expect(msg.content).to include('Confira nossas ofertas de SUV')
        expect(msg.content).not_to include('não suportada')
        expect(msg.content_attributes['unsupported']).to be_nil
      end

      it 'cobre o nome legado hydratedFourRowTemplate' do
        params = {
          jsonData: json_data(
            'templateMessage' => {
              'hydratedFourRowTemplate' => { 'hydratedContentText' => 'Texto do template' },
            },
          ),
        }
        described_class.new(inbox: inbox, params: params).perform

        expect(inbox.messages.last.content).to eq('Texto do template')
      end
    end

    context 'when a ptvMessage (vídeo-nota / PTV) arrives' do
      it 'anexa como vídeo em vez de "[mensagem não suportada]"' do
        params = { jsonData: json_data('ptvMessage' => { 'mimetype' => 'video/mp4' }), file: file_param }
        described_class.new(inbox: inbox, params: params).perform

        msg = inbox.messages.last
        expect(msg.attachments.first).to be_present
        expect(msg.content).not_to include('não suportada')
        expect(msg.content_attributes['unsupported']).to be_nil
      end

      it 'sem binário inline: baixa via /message/download e anexa' do
        params = { jsonData: json_data('ptvMessage' => { 'mimetype' => 'video/mp4' }) }
        allow_any_instance_of(Whatsapp::Providers::AvisaClient)
          .to receive(:download_media).and_return('fake-mp4-bytes')

        described_class.new(inbox: inbox, params: params).perform
        expect(inbox.messages.last.attachments.first).to be_present
      end
    end
  end

  # CUSTOMIZAÇÃO_SYNAPSEOS: o fykos removeu o branch lock_to_single_conversation;
  # nós o mantemos (Alice/Angela). Cobre os dois modos.
  describe '#find_or_create_conversation (lock_to_single_conversation)' do
    let(:account) { create(:account) }
    let(:contact) { create(:contact, account: account) }

    def service_for(target_inbox)
      described_class.new(inbox: target_inbox, params: {})
    end

    context 'when the inbox locks to a single conversation' do
      let(:locked_inbox) { create(:inbox, account: account, lock_to_single_conversation: true) }
      let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: locked_inbox) }

      it 'reuses the last conversation even when resolved, reopening it' do
        resolved = create(:conversation, account: account, inbox: locked_inbox,
                                         contact: contact, contact_inbox: contact_inbox, status: :resolved)
        result = service_for(locked_inbox).send(:find_or_create_conversation, contact_inbox)
        expect(result.id).to eq(resolved.id)
        expect(result.reload.status).to eq('open')
      end

      it 'creates a conversation when the contact has none' do
        expect do
          service_for(locked_inbox).send(:find_or_create_conversation, contact_inbox)
        end.to change(Conversation, :count).by(1)
      end
    end

    context 'when the inbox does not lock' do
      let(:open_inbox) { create(:inbox, account: account, lock_to_single_conversation: false) }
      let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: open_inbox) }

      it 'ignores a resolved conversation and creates a new one' do
        create(:conversation, account: account, inbox: open_inbox,
                              contact: contact, contact_inbox: contact_inbox, status: :resolved)
        expect do
          service_for(open_inbox).send(:find_or_create_conversation, contact_inbox)
        end.to change(Conversation, :count).by(1)
      end

      it 'reuses an open conversation' do
        open_conversation = create(:conversation, account: account, inbox: open_inbox,
                                                  contact: contact, contact_inbox: contact_inbox, status: :open)
        result = service_for(open_inbox).send(:find_or_create_conversation, contact_inbox)
        expect(result.id).to eq(open_conversation.id)
      end
    end
  end
end
