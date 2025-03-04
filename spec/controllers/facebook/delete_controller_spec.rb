require 'rails_helper'

RSpec.describe Facebook::DeleteController do
  describe 'POST #create' do
    let(:user_id) { '12345' }
    let(:app_secret) { 'test_app_secret' }
    let(:frontend_url) { ENV.fetch('FRONTEND_URL', nil) }
    let(:redis_key) { format(Redis::Alfred::META_DELETE_PROCESSING, id: user_id) }

    before do
      allow(GlobalConfigService).to receive(:load).with('FB_APP_SECRET', '').and_return(app_secret)
    end

    context 'with valid signed request' do
      let(:payload) { { 'user_id' => user_id }.to_json }
      let(:encoded_payload) { Base64.urlsafe_encode64(payload) }
      let(:signature) { OpenSSL::HMAC.digest('sha256', app_secret, encoded_payload) }
      let(:encoded_signature) { Base64.urlsafe_encode64(signature) }
      let(:signed_request) { "#{encoded_signature}.#{encoded_payload}" }

      before do
        allow(Redis::Alfred).to receive(:set)
        allow(Channels::Facebook::RedactContactDataJob).to receive(:perform_later)
      end

      it 'processes the delete request and returns status URL' do
        post :create, params: { signed_request: signed_request }

        expect(Redis::Alfred).to have_received(:set).with(redis_key, true)
        expect(Channels::Facebook::RedactContactDataJob).to have_received(:perform_later).with(user_id)

        expect(response).to have_http_status(:ok)

        response_json = response.parsed_body
        # NOTE: this is an important condition since this is exactly the format facebook expects
        expect(response_json['url']).to eq("#{frontend_url}/facebook/confirm/#{user_id}")
        expect(response_json['confirmation_code']).to eq(user_id)
      end
    end

    context 'with invalid signed request' do
      let(:invalid_signed_request) { 'invalid_signature.invalid_payload' }

      before do
        # Mock the Base64.urlsafe_decode64 to return valid values for testing
        allow(Base64).to receive(:urlsafe_decode64).with('invalid_signature').and_return('decoded_signature')
        allow(Base64).to receive(:urlsafe_decode64).with('invalid_payload').and_return('{"user_id":"12345"}')
        allow(JSON).to receive(:parse).with('{"user_id":"12345"}').and_return({ 'user_id' => user_id })
        allow(OpenSSL::HMAC).to receive(:digest).and_return('different_signature')
      end

      it 'returns an error for invalid signature' do
        post :create, params: { signed_request: invalid_signed_request }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
