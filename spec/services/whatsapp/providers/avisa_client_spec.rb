require 'rails_helper'

# CUSTOMIZAÇÃO_SYNAPSEOS: o /message/download/audio retorna o base64 em shapes
# variados. Em prod observamos {status, data} (log 19/06) — o extract_base64
# antigo só olhava Data/data/file no topo e em response['data'] como Hash, então
# perdia {data: "<b64>"} e devolvia vazio (áudio nunca anexava).
RSpec.describe Whatsapp::Providers::AvisaClient do
  subject(:client) { described_class.new(api_key: 'k') }

  # base64 plausível (>50 chars do charset base64)
  let(:b64) { Base64.strict_encode64('a' * 120) }

  def extract(resp)
    client.send(:extract_base64, resp)
  end

  describe '#extract_base64' do
    it 'acha base64 em {status, data: "<b64>"} (shape de prod)' do
      expect(extract('status' => 'success', 'data' => b64)).to eq(b64)
    end

    it 'acha base64 aninhado em {status, data: {base64: "<b64>"}}' do
      expect(extract('status' => 'ok', 'data' => { 'base64' => b64 })).to eq(b64)
    end

    it 'acha base64 em {Data: "<b64>"} (top-level legado)' do
      expect(extract('Data' => b64)).to eq(b64)
    end

    it 'acha base64 sob chave inesperada via fallback recursivo' do
      expect(extract('status' => 'ok', 'data' => { 'arquivo_audio' => b64 })).to eq(b64)
    end

    it 'tira o prefixo data: do data URI' do
      expect(extract('data' => "data:audio/ogg;base64,#{b64}")).to eq(b64)
    end

    it 'retorna nil quando não há base64 (só metadados curtos)' do
      expect(extract('status' => 'error', 'data' => { 'msg' => 'not found' })).to be_nil
    end

    it 'ignora strings curtas (não confunde status com base64)' do
      expect(extract('status' => 'success', 'data' => {})).to be_nil
    end
  end

  # CUSTOMIZAÇÃO_SYNAPSEOS: a Avisa mudou o envelope da resposta de send*
  # (~jun/2026) de data.response.data para data.data. O extrator rígido parou de
  # achar o Id → 100% das outgoing viravam "sem Id" (source_id null, marcadas
  # failed) mesmo entregues (26/06→30/06). extract_send_result é robusto ao shape.
  describe '#extract_send_result' do
    def result(resp)
      client.send(:extract_send_result, resp)
    end

    it 'acha o Id no shape ANTIGO data.response.data' do
      resp = { 'data' => { 'response' => { 'data' => { 'Id' => '3EB0ADEDE7B1', 'Timestamp' => 111 } } } }
      expect(result(resp)).to eq(id: '3EB0ADEDE7B1', timestamp: 111)
    end

    it 'acha o Id no shape NOVO data.data (mesmo do /instance/status)' do
      resp = { 'status' => true, 'data' => { 'code' => 200, 'data' => { 'Id' => 'BAE5F00D1234', 'Timestamp' => 222 }, 'success' => true } }
      expect(result(resp)[:id]).to eq('BAE5F00D1234')
    end

    it 'acha o Id via busca recursiva em shape inesperado' do
      expect(result('x' => { 'y' => [{ 'Id' => '3AF0FEEDCAFE99' }] })[:id]).to eq('3AF0FEEDCAFE99')
    end

    it 'retorna id nil quando a resposta não traz Id (envio não confirmado)' do
      resp = { 'status' => true, 'data' => { 'code' => 200, 'data' => { 'Connected' => true }, 'success' => true } }
      expect(result(resp)[:id]).to be_nil
    end

    it 'não confunde Jid/code com o Id da mensagem' do
      expect(result('data' => { 'data' => { 'Jid' => '5534@s.whatsapp.net', 'code' => 200 } })[:id]).to be_nil
    end
  end

  # CUSTOMIZAÇÃO_SYNAPSEOS: heurística de "conectado" do /instance/status
  # (porta do monitor n8n audi instance_watch). true|false|nil (indeterminado).
  describe '#interpret_connected' do
    def connected(code, body)
      client.send(:interpret_connected, code, body)
    end

    it 'nil quando indeterminado (5xx) ou sem code (timeout)' do
      expect(connected(500, {})).to be_nil
      expect(connected(nil, { 'error' => 'timeout' })).to be_nil
    end

    it 'false em 4xx' do
      expect(connected(401, {})).to be(false)
      expect(connected(404, {})).to be(false)
    end

    it 'true/false por flag booleana explícita' do
      expect(connected(200, { 'connected' => true })).to be(true)
      expect(connected(200, { 'loggedIn' => true })).to be(true)
      expect(connected(200, { 'connected' => false })).to be(false)
    end

    it 'true por state/status conectado' do
      expect(connected(200, { 'state' => 'open' })).to be(true)
      expect(connected(200, { 'status' => 'connected' })).to be(true)
      expect(connected(200, { 'data' => { 'state' => 'online' } })).to be(true)
    end

    it 'false por state/status desconectado' do
      expect(connected(200, { 'state' => 'close' })).to be(false)
      expect(connected(200, { 'status' => 'qrcode' })).to be(false)
      expect(connected(200, { 'instance' => { 'state' => 'unpaired' } })).to be(false)
    end

    it 'false quando o corpo cheira a desconexão (fallback textual)' do
      expect(connected(200, { 'message' => 'device logged out' })).to be(false)
    end

    it 'true como fallback em 2xx sem sinal de queda' do
      expect(connected(200, { 'foo' => 'bar' })).to be(true)
    end
  end
end
