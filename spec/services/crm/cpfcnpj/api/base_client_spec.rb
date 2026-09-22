require 'rails_helper'

RSpec.describe Crm::Cpfcnpj::Api::BaseClient do
  let(:token) { 'a' * 32 }
  let(:client) { described_class.new(token: token) }
  let(:document) { '11222333000181' }

  describe '#lookup' do
    context 'when the API returns a successful payload' do
      let(:payload) { { 'status' => 1, 'cnpj' => '11.222.333/0001-81', 'razao' => 'TOKEN TEST LTDA' } }

      before do
        stub_request(:get, "https://api.cpfcnpj.com.br/#{token}/6/#{document}")
          .to_return(status: 200, body: payload.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns the parsed body' do
        expect(client.lookup(document, 6)).to include('razao' => 'TOKEN TEST LTDA')
      end
    end

    context 'when the API returns a domain error' do
      let(:payload) { { 'status' => 0, 'cpf' => '', 'erro' => 'Informe um CPF com 11 digitos!', 'erroCodigo' => 101 } }

      before do
        stub_request(:get, "https://api.cpfcnpj.com.br/#{token}/1/123")
          .to_return(status: 400, body: payload.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises ApiError carrying the erroCodigo' do
        expect { client.lookup('123', 1) }.to raise_error(described_class::ApiError) do |error|
          expect(error.code).to eq(101)
          expect(error.message).to include('101')
        end
      end

      it 'does not leak the token in the error message' do
        expect { client.lookup('123', 1) }.to raise_error(described_class::ApiError) do |error|
          expect(error.message).not_to include(token)
        end
      end
    end

    context 'when the API returns a routing error' do
      let(:payload) { { 'status' => 'error', 'code' => 400, 'message' => 'Incorrect parameters.' } }

      before do
        stub_request(:get, "https://api.cpfcnpj.com.br/#{token}/99/#{document}")
          .to_return(status: 400, body: payload.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises ApiError with the routing code' do
        expect { client.lookup(document, 99) }.to raise_error(described_class::ApiError) do |error|
          expect(error.code).to eq(400)
        end
      end
    end

    context 'when the request times out' do
      before do
        stub_request(:get, "https://api.cpfcnpj.com.br/#{token}/6/#{document}").to_timeout
      end

      it 'raises the underlying timeout error' do
        expect { client.lookup(document, 6) }.to raise_error(Net::OpenTimeout)
      end
    end
  end

  describe 'timeout' do
    it 'waits up to 60 seconds for the registry lookup' do
      expect(described_class.default_options[:timeout]).to eq(60)
    end
  end
end
