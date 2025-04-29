require 'rails_helper'

describe Digitaltolk::Auth::Refresh do
  subject { described_class.new(user_auth.refresh_token, client_id: 'test', tenant: 'test') }

  let(:user_auth) { create(:user_auth) }
  let(:successful_response) do
    {
      'token_type': 'Bearer',
      'expires_in': 2_592_000,
      'access_token': 'access_token_test',
      'refresh_token': 'refresh_token_test'
    }
  end
  let(:stub_body) do
    {
      'grant_type': 'refresh_token',
      'client_id': 'test',
      'tenant': 'test',
      'refresh_token': user_auth.refresh_token
    }
  end

  describe '#perform' do
    context 'when response is sucessful' do
      before do
        stub_request(:post, Digitaltolk::Auth::Generate::API_URL)
          .with(body: stub_body.to_json)
          .to_return(status: 200, body: successful_response.to_json, headers: {})
      end

      it 'returns a hash with token information' do
        response = subject.perform
        expect(response).to eq(successful_response.stringify_keys)
      end
    end

    context 'when response is not successful' do
      before do
        stub_request(:post, Digitaltolk::Auth::Generate::API_URL)
          .with(body: stub_body.to_json)
          .to_return(status: 500, body: '', headers: {})
      end

      it 'raises an error' do
        expect { subject.perform }.to raise_error(RuntimeError, 'Failed to generate token: 500')
      end
    end
  end
end
