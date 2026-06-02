require 'rails_helper'

RSpec.describe 'Health Check', type: :request do
  describe 'GET /health' do
    it 'returns success status' do
      get '/health'
      expect(response).to have_http_status(:success)
      expect(response.parsed_body['status']).to eq('woot')
    end
  end
end
