# frozen_string_literal: true

require 'rails_helper'

# CUSTOMIZAÇÃO_SYNAPSEOS: o envio de TEXTO precisa marcar a mensagem como `failed`
# quando a Avisa não devolve Id (sessão desconectada → 2xx-sem-Id) ou quando o HTTP
# falha. Sem isso a msg fica "sent + source_id null" = relógio eterno no UI.
describe Whatsapp::Providers::AvisaService do
  subject(:service) { described_class.new(whatsapp_channel: channel) }

  let(:channel) do
    create(:channel_whatsapp, provider: 'avisa',
                              provider_config: { 'api_key' => 'k', 'base_url' => 'https://avisa.test' },
                              validate_provider_config: false, sync_templates: false)
  end
  let(:conversation) { create(:conversation, inbox: channel.inbox) }
  let(:message) do
    create(:message, conversation: conversation, message_type: :outgoing, content: 'olá', inbox: channel.inbox)
  end
  let(:json_headers) { { 'Content-Type' => 'application/json' } }

  def stub_send(status:, body:)
    stub_request(:post, 'https://avisa.test/actions/sendMessage')
      .to_return(status: status, body: body.is_a?(String) ? body : body.to_json, headers: json_headers)
  end

  describe '#send_message (texto)' do
    it 'retorna o Id e NÃO marca failed quando a Avisa confirma o envio' do
      stub_send(status: 200, body: { data: { response: { data: { 'Id' => '3EB0OK', 'Timestamp' => '1' } } } })

      expect(service.send_message('5534999990000', message)).to eq('3EB0OK')
      expect(message.reload.status).not_to eq('failed')
    end

    it 'marca failed quando a Avisa responde 2xx SEM Id (sessão desconectada)' do
      stub_send(status: 200, body: { data: { response: { data: {} } } })

      expect(service.send_message('5534999990000', message)).to be_nil
      expect(message.reload.status).to eq('failed')
      expect(message.reload.external_error).to include('sem Id')
    end

    it 'marca failed quando o HTTP da Avisa falha (ex.: 401)' do
      stub_send(status: 401, body: 'unauthorized')

      expect(service.send_message('5534999990000', message)).to be_nil
      expect(message.reload.status).to eq('failed')
      expect(message.reload.external_error).to start_with('Avisa:')
    end
  end
end
