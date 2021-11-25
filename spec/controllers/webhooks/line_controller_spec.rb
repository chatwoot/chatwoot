require 'rails_helper'

RSpec.describe 'Webhooks::LineController', type: :request do
  describe 'POST /webhooks/line/{:line_channel_id}' do
    it 'call the line events job with the params' do
      allow(Webhooks::LineEventsJob).to receive(:perform_later)
      expect(Webhooks::LineEventsJob).to receive(:perform_later)
      post '/webhooks/line/line_channel_id', params: { content: 'hello' }
      expect(response).to have_http_status(:success)
    end
  end
end
