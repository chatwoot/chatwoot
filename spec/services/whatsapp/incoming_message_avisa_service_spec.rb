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

  # CUSTOMIZAÇÃO_SYNAPSEOS: o webhook do Avisa NÃO anexa o arquivo de áudio
  # (.enc). Antes, áudio inbound era dropado (texto blank + file blank) e a
  # conversa ficava só com as respostas da Elisa ("respondendo sozinha", conv
  # 162). Agora baixamos o áudio decriptado e anexamos -> balão de incoming
  # real com player. Criado pelo model (bypassa a validação "Api inboxes").
  describe '#perform with inbound audio' do
    # Inbox simples + stub do avisa_client (único uso da provider no caminho de
    # áudio). Evita a factory de channel_whatsapp com provider 'avisa', que não
    # passa nas validações de provider_config no ambiente de teste.
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

    it 'baixa o áudio decriptado e cria incoming com anexo de áudio (player)' do
      stub_download('FAKE_OGG_BYTES')

      service.perform

      msg = Message.find_by(source_id: 'AUDIOMSG1', inbox_id: inbox.id)
      expect(msg).to be_present
      expect(msg.message_type).to eq('incoming')
      expect(msg.attachments.count).to eq(1)
      expect(msg.attachments.first.file_type).to eq('audio')
    end

    it 'não cria mensagem quando o download do áudio falha (sem texto, sem arquivo)' do
      stub_download(nil)

      service.perform

      expect(Message.find_by(source_id: 'AUDIOMSG1', inbox_id: inbox.id)).to be_nil
    end
  end
end
