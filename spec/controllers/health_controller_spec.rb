require 'rails_helper'

RSpec.describe 'Health Check', type: :request do
  describe 'GET /health' do
    it 'returns success status' do
      get '/health'
      expect(response).to have_http_status(:success)
      expect(response.parsed_body['status']).to eq('woot')
    end

    it 'returns fazer.ai platform info' do
      get '/health'
      expect(response.parsed_body['platform']).to eq('fazer.ai')
      expect(response.parsed_body['version']).to eq(Chatwoot.config[:version])
    end

    it 'includes X-Platform header' do
      get '/health'
      expect(response.headers['X-Platform']).to eq('fazer.ai')
    end
  end
end
