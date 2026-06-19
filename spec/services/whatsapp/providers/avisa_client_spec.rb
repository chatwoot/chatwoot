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
end
