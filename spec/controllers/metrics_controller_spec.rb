# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Prometheus metrics', type: :request do
  after { ChatwootPrometheus.reset! }

  describe 'GET /metrics' do
    it 'returns 404 when ENABLE_PROMETHEUS is unset' do
      get '/metrics'
      expect(response).to have_http_status(:not_found)
    end

    it 'returns Prometheus text when ENABLE_PROMETHEUS is true' do
      with_modified_env ENABLE_PROMETHEUS: 'true' do
        ChatwootPrometheus.reset!
        get '/metrics'
      end

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq('text/plain')
      expect(response.body).to include('chatwoot_up')
      expect(response.body).to match(/chatwoot_up(?:\{[^}]*\})? 1(?:\.0)?/)
    end
  end
end
