require 'rails_helper'

RSpec.describe 'Public Inbox API', type: :request do
  let!(:api_channel) { create(:channel_api) }

  describe 'GET /public/api/v1/inboxes/{identifier}' do
    it 'is able to fetch the details of an inbox' do
      get "/public/api/v1/inboxes/#{api_channel.identifier}"

      expect(response).to have_http_status(:success)
      data = response.parsed_body

      expect(data.keys).to include('name', 'timezone', 'working_hours', 'working_hours_enabled')
      expect(data.keys).to include('csat_survey_enabled', 'greeting_enabled', 'identity_validation_enabled')
      expect(data['identifier']).to eq api_channel.identifier
    end
  end
end
