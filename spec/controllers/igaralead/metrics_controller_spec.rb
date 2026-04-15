# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Igaralead::MetricsController, type: :request do
  let(:metrics_key) { 'test-metrics-key' }
  let!(:account) { create(:account, hub_client_slug: 'test-slug') }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('HUB_METRICS_API_KEY', '').and_return(metrics_key)
  end

  describe 'GET /igaralead/metrics/:client_slug' do
    it 'rejects metrics request without API key' do
      get '/igaralead/metrics/test-slug'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects metrics request with wrong API key' do
      get '/igaralead/metrics/test-slug',
          headers: { 'X-Api-Key' => 'wrong-key' }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns metrics with valid API key' do
      get '/igaralead/metrics/test-slug',
          headers: { 'X-Api-Key' => metrics_key }
      expect(response).not_to have_http_status(:unauthorized)
    end

    it 'returns 404 for nonexistent client_slug' do
      get '/igaralead/metrics/nonexistent-slug',
          headers: { 'X-Api-Key' => metrics_key }
      expect(response).to have_http_status(:not_found)
    end

    it 'does not leak sensitive data in response' do
      get '/igaralead/metrics/test-slug',
          headers: { 'X-Api-Key' => metrics_key }
      next unless response.successful?

      body = response.body
      expect(body).not_to include('password')
      expect(body).not_to include('secret')
      expect(body).not_to include('api_key')
    end
  end
end
