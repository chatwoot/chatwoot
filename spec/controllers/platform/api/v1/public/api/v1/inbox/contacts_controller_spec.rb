require 'rails_helper'

RSpec.describe 'Public Inbox Contacts API', type: :request do
  let!(:api_channel) { create(:channel_api) }

  describe 'POST /public/api/v1/inboxes/{identifier}/contact' do
    it 'creates a contact and return the source id' do
      post "/public/api/v1/inboxes/#{api_channel.identifier}/contacts"
          
      expect(response).to have_http_status(:success)
      data = JSON.parse(response.body)
      expect(data['source_id']).not_to eq nil
    end
  end
end
