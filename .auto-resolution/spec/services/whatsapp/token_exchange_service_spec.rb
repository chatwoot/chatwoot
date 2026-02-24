require 'rails_helper'

describe Whatsapp::TokenExchangeService do
  let(:code) { 'test_authorization_code' }
  let(:service) { described_class.new(code) }
  let(:api_client) { instance_double(Whatsapp::FacebookApiClient) }

  before do
    allow(Whatsapp::FacebookApiClient).to receive(:new).and_return(api_client)
  end

  describe '#perform' do
    context 'when code is valid' do
      let(:token_response) { { 'access_token' => 'new_access_token' } }

      before do
        allow(api_client).to receive(:exchange_code_for_token).with(code).and_return(token_response)
      end

      it 'returns the access token' do
        expect(service.perform).to eq('new_access_token')
      end
    end

    context 'when code is blank' do
      let(:service) { described_class.new('') }

      it 'raises ArgumentError' do
        expect { service.perform }.to raise_error(ArgumentError, 'Authorization code is required')
      end
    end

    context 'when response has no access token' do
      let(:token_response) { { 'error' => 'Invalid code' } }

      before do
        allow(api_client).to receive(:exchange_code_for_token).with(code).and_return(token_response)
      end

      it 'raises an error' do
        expect { service.perform }.to raise_error(/No access token in response/)
      end
    end
  end
end
