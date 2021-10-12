require 'rails_helper'

RSpec.describe 'Webhooks::InstagramController', type: :request do
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
