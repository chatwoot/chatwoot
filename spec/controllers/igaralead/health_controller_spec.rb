# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Igaralead::HealthController, type: :request do
  describe 'GET /igaralead/health' do
    it 'returns health status without authentication' do
      get '/igaralead/health'
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['product']).to eq('nexus')
      expect(body['status']).to be_in(%w[ok degraded])
      expect(body['checks']).to include('api', 'database', 'redis')
    end

    it 'does not leak sensitive configuration' do
      get '/igaralead/health'
      body = response.body
      expect(body).not_to include('SECRET')
      expect(body).not_to include('PASSWORD')
      expect(body).not_to include('API_KEY')
    end

    it 'responds with JSON content type' do
      get '/igaralead/health'
      expect(response.content_type).to include('application/json')
    end
  end
end
