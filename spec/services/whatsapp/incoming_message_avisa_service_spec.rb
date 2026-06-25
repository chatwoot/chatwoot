# frozen_string_literal: true

require 'rails_helper'

# CUSTOMIZAÇÃO_SYNAPSEOS
RSpec.describe Whatsapp::IncomingMessageAvisaService do
  let(:account) { create(:account) }
  let(:contact) { create(:contact, account: account) }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }

  subject(:service) { described_class.new(inbox: inbox, params: {}) }

  describe '#find_or_create_conversation' do
    context 'when the inbox locks to a single conversation' do
      let(:inbox) { create(:inbox, account: account, lock_to_single_conversation: true) }

      it 'reuses the last conversation even when it is resolved, reopening it' do
        resolved = create(:conversation, account: account, inbox: inbox,
                                         contact: contact, contact_inbox: contact_inbox,
                                         status: :resolved)

        result = service.send(:find_or_create_conversation, contact_inbox)

        expect(result.id).to eq(resolved.id)
        expect(result.reload.status).to eq('open')
      end

      it 'reuses an already-open conversation without touching its status' do
        open_conversation = create(:conversation, account: account, inbox: inbox,
                                                  contact: contact, contact_inbox: contact_inbox,
                                                  status: :open)

        result = service.send(:find_or_create_conversation, contact_inbox)

        expect(result.id).to eq(open_conversation.id)
        expect(result.status).to eq('open')
      end

      it 'creates a conversation when the contact has none' do
        expect do
          result = service.send(:find_or_create_conversation, contact_inbox)
          expect(result.contact_inbox_id).to eq(contact_inbox.id)
        end.to change(Conversation, :count).by(1)
      end
    end

    context 'when the inbox does not lock to a single conversation' do
      let(:inbox) { create(:inbox, account: account, lock_to_single_conversation: false) }

      it 'ignores a resolved conversation and creates a new one (legacy behaviour)' do
        create(:conversation, account: account, inbox: inbox,
                              contact: contact, contact_inbox: contact_inbox,
                              status: :resolved)

        expect do
          service.send(:find_or_create_conversation, contact_inbox)
        end.to change(Conversation, :count).by(1)
      end

      it 'reuses an open conversation' do
        open_conversation = create(:conversation, account: account, inbox: inbox,
                                                  contact: contact, contact_inbox: contact_inbox,
                                                  status: :open)

        result = service.send(:find_or_create_conversation, contact_inbox)

        expect(result.id).to eq(open_conversation.id)
      end
    end
  end

  # CUSTOMIZAÇÃO_SYNAPSEOS: o webhook do Avisa não anexa o arquivo de áudio.
  # Baixamos o áudio decriptado e anexamos à incoming -> o anexo de áudio
  # aciona a transcrição NATIVA do Chatwoot. Antes o áudio era dropado (conv 162).
  describe '#perform with inbound audio' do
    let(:inbox) { create(:inbox, account: account) }
    let(:audio_event) do
      {
        'Info' => { 'ID' => 'AUDIOMSG1', 'Chat' => '5534999887766@s.whatsapp.net', 'PushName' => 'Cliente' },
        'Message' => { 'audioMessage' => {
          'URL' => 'https://wa/audio.enc', 'directPath' => '/v/t', 'mediaKey' => 'mk',
          'mimetype' => 'audio/ogg; codecs=opus', 'fileEncSHA256' => 'e',
          'fileSHA256' => 's', 'fileLength' => 2048
        } }
      }
    end

    subject(:service) { described_class.new(inbox: inbox, params: { jsonData: { 'event' => audio_event }.to_json }) }

    def stub_download(return_value)
      client = instance_double(Whatsapp::Providers::AvisaClient, download_audio: return_value)
      allow(service).to receive(:avisa_client).and_return(client)
    end

    it 'baixa o áudio decriptado e cria incoming com anexo de áudio' do
      stub_download('FAKE_OGG_BYTES')

      service.perform

      msg = Message.find_by(source_id: 'AUDIOMSG1', inbox_id: inbox.id)
      expect(msg).to be_present
      expect(msg.message_type).to eq('incoming')
      expect(msg.attachments.count).to eq(1)
      expect(msg.attachments.first.file_type).to eq('audio')
    end

    it 'cria placeholder incoming quando o download do áudio falha (não some mais)' do
      stub_download(nil)

      service.perform

      msg = Message.find_by(source_id: 'AUDIOMSG1', inbox_id: inbox.id)
      expect(msg).to be_present
      expect(msg.message_type).to eq('incoming')
      expect(msg.content).to include('áudio')
      expect(msg.attachments).to be_empty
    end
  end

  # CUSTOMIZAÇÃO_SYNAPSEOS: figurinha/imagem/vídeo/documento que o Avisa NÃO
  # entrega inline (params[:file] ausente) são BAIXADOS via /message/download/
  # {kind} e anexados, em vez de virar placeholder. Repro conv 254 (figurinha
  # virava "[O cliente enviou uma figurinha que não pôde ser exibido...]").
  describe '#perform with downloaded media (Avisa não inlina o binário)' do
    let(:inbox) { create(:inbox, account: account) }

    def media_event(key, id, mimetype)
      {
        'Info' => { 'ID' => id, 'Chat' => '5534999887766@s.whatsapp.net', 'PushName' => 'Cliente' },
        'Message' => { key => {
          'URL' => 'https://wa/media.enc', 'directPath' => '/v/t', 'mediaKey' => 'mk',
          'mimetype' => mimetype, 'fileEncSHA256' => 'e', 'fileSHA256' => 's', 'fileLength' => 1024
        } }
      }
    end

    def build_service(event)
      described_class.new(inbox: inbox, params: { jsonData: { 'event' => event }.to_json })
    end

    def stub_download_media(svc, return_value)
      client = instance_double(Whatsapp::Providers::AvisaClient, download_media: return_value)
      allow(svc).to receive(:avisa_client).and_return(client)
    end

    it 'baixa a figurinha (sticker) e cria incoming com anexo de imagem (não placeholder)' do
      svc = build_service(media_event('stickerMessage', 'STK1', 'image/webp'))
      stub_download_media(svc, 'FAKE_WEBP_BYTES')

      svc.perform

      msg = Message.find_by(source_id: 'STK1', inbox_id: inbox.id)
      expect(msg).to be_present
      expect(msg.message_type).to eq('incoming')
      expect(msg.attachments.count).to eq(1)
      expect(msg.attachments.first.file_type).to eq('image')
    end

    it 'baixa a imagem quando o Avisa não anexa o binário inline' do
      svc = build_service(media_event('imageMessage', 'IMG1', 'image/jpeg'))
      stub_download_media(svc, 'FAKE_JPG_BYTES')

      svc.perform

      msg = Message.find_by(source_id: 'IMG1', inbox_id: inbox.id)
      expect(msg.attachments.first.file_type).to eq('image')
    end

    it 'baixa o vídeo quando o Avisa não anexa o binário inline' do
      svc = build_service(media_event('videoMessage', 'VID1', 'video/mp4'))
      stub_download_media(svc, 'FAKE_MP4_BYTES')

      svc.perform

      msg = Message.find_by(source_id: 'VID1', inbox_id: inbox.id)
      expect(msg.attachments.first.file_type).to eq('video')
    end

    it 'cai no placeholder de figurinha quando o download falha (best-effort, sem regressão)' do
      svc = build_service(media_event('stickerMessage', 'STK2', 'image/webp'))
      stub_download_media(svc, nil)

      svc.perform

      msg = Message.find_by(source_id: 'STK2', inbox_id: inbox.id)
      expect(msg).to be_present
      expect(msg.content).to include('figurinha')
      expect(msg.attachments).to be_empty
    end
  end

  # CUSTOMIZAÇÃO_SYNAPSEOS: inbound sem texto e sem mídia anexável (tipo não
  # suportado) NÃO pode virar conversa-casca silenciosa (conv 380) — vira um
  # placeholder incoming visível.
  describe '#perform with unsupported inbound (sem texto/mídia)' do
    let(:inbox) { create(:inbox, account: account) }
    let(:loc_event) do
      {
        'Info' => { 'ID' => 'LOCMSG1', 'Chat' => '5534999793594@s.whatsapp.net',
                    'PushName' => 'Cliente', 'Type' => 'media', 'MediaType' => 'location' },
        'Message' => { 'locationMessage' => { 'degreesLatitude' => -18.9, 'degreesLongitude' => -48.2 } }
      }
    end

    subject(:service) { described_class.new(inbox: inbox, params: { jsonData: { 'event' => loc_event }.to_json }) }

    it 'cria um placeholder incoming visível em vez de conversa vazia' do
      service.perform

      msg = Message.find_by(source_id: 'LOCMSG1', inbox_id: inbox.id)
      expect(msg).to be_present
      expect(msg.message_type).to eq('incoming')
      expect(msg.content).to include('não pôde ser exibido')
    end

    it 'descarta echo do próprio número sem conteúdo (não cria placeholder)' do
      loc_event['Info']['IsFromMe'] = true

      service.perform

      expect(Message.find_by(source_id: 'LOCMSG1', inbox_id: inbox.id)).to be_nil
    end
  end
end
