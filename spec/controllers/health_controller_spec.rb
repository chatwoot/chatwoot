require 'rails_helper'

RSpec.describe 'Health Check', type: :request do
  describe 'GET /health' do
    it 'returns success status' do
      get '/health'
      expect(response).to have_http_status(:success)
      expect(response.parsed_body['status']).to eq('woot')
    end
  end

  describe 'GET /health/ready' do
    it 'returns success when postgres and redis are reachable' do
      get '/health/ready'
      expect(response).to have_http_status(:success)
      expect(response.parsed_body['status']).to eq('ready')
    end

    it 'returns 503 when redis is unreachable' do
      allow(Redis).to receive(:new).and_raise(Redis::CannotConnectError)

      get '/health/ready'
      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body['status']).to eq('unavailable')
    end

    it 'returns 503 when postgres is unreachable' do
      allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(ActiveRecord::ConnectionNotEstablished)

      get '/health/ready'
      expect(response).to have_http_status(:service_unavailable)
    end
  end
end
