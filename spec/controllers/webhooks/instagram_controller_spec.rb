require 'rails_helper'

RSpec.describe 'Webhooks::InstagramController', type: :request do
  describe 'GET /webhooks/verify' do
    it 'returns 401 when valid params are not present' do
      get '/webhooks/instagram/verify'
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 401 when invalid params' do
      with_modified_env IG_VERIFY_TOKEN: '123456' do
        get '/webhooks/instagram/verify', params: { 'hub.challenge' => '123456', 'hub.mode' => 'subscribe', 'hub.verify_token' => 'invalid' }
        expect(response).to have_http_status(:not_found)
      end
    end

    it 'returns challenge when valid params' do
      with_modified_env IG_VERIFY_TOKEN: '123456' do
        get '/webhooks/instagram/verify', params: { 'hub.challenge' => '123456', 'hub.mode' => 'subscribe', 'hub.verify_token' => '123456' }
        expect(response.body).to include '123456'
      end
    end
  end

  describe 'POST /webhooks/instagram' do
    let!(:dm_params) { build(:instagram_message_create_event).with_indifferent_access }

    it 'call the instagram events job with the params' do
      allow(::Webhooks::InstagramEventsJob).to receive(:perform_later)
      expect(::Webhooks::InstagramEventsJob).to receive(:perform_later)

      instagram_params = dm_params.merge(object: 'instagram')
      post '/webhooks/instagram', params: instagram_params
      expect(response).to have_http_status(:success)
    end
  end
end
