# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Prometheus metrics', type: :request do
  after { ChatwootPrometheus.reset! }

  describe 'GET /metrics' do
    it 'returns 404 when ENABLE_PROMETHEUS is unset' do
      with_modified_env ENABLE_PROMETHEUS: nil do
        get '/metrics'
      end

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when ENABLE_PROMETHEUS is false' do
      with_modified_env ENABLE_PROMETHEUS: 'false' do
        get '/metrics'
      end

      expect(response).to have_http_status(:not_found)
    end

    it 'returns Prometheus text when ENABLE_PROMETHEUS is true' do # rubocop:disable RSpec/MultipleExpectations
      stats = instance_double(
        Sidekiq::Stats,
        processed: 10,
        failed: 2,
        enqueued: 3,
        retry_size: 1,
        dead_size: 4,
        workers_size: 5
      )
      allow(Sidekiq::Stats).to receive(:new).and_return(stats)
      allow(Sidekiq::Queue).to receive(:all).and_return(
        [instance_double(Sidekiq::Queue, latency: 1.5), instance_double(Sidekiq::Queue, latency: 0.25)]
      )

      with_modified_env ENABLE_PROMETHEUS: 'true' do
        ChatwootPrometheus.reset!
        get '/metrics'
      end

      expect(response).to have_http_status(:success)
      expect(response.media_type).to start_with('text/plain')
      expect(response.content_type).to include('version=0.0.4')
      expect(response.body).to match(/chatwoot_up(?:\{[^}]*\})? 1(?:\.0)?/)
      expect(response.body).to match(/chatwoot_sidekiq_scrape_success(?:\{[^}]*\})? 1(?:\.0)?/)
      expect(response.body).to include('chatwoot_sidekiq_processed')
      expect(response.body).to include('chatwoot_sidekiq_enqueued')
      expect(response.body).to include('chatwoot_sidekiq_queue_latency_seconds')
      expect(response.body).not_to include('inbox_id')
      expect(response.body).not_to include('account_id')
      expect(response.body).not_to include('user_id')
    end
  end
end
