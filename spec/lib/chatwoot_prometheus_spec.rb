# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ChatwootPrometheus do
  after { described_class.reset! }

  describe '.enabled?' do
    it 'is false when the env is unset' do
      with_modified_env ENABLE_PROMETHEUS: nil do
        expect(described_class.enabled?).to be(false)
      end
    end

    it 'is true when ENABLE_PROMETHEUS is true' do
      with_modified_env ENABLE_PROMETHEUS: 'true' do
        expect(described_class.enabled?).to be(true)
      end
    end
  end

  describe '.text' do
    it 'emits chatwoot_up and Sidekiq snapshot gauges' do # rubocop:disable RSpec/MultipleExpectations
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
      allow(Sidekiq::Queue).to receive(:all).and_return([instance_double(Sidekiq::Queue, latency: 1.5)])

      body = described_class.text

      expect(body).to match(/chatwoot_up(?:\{[^}]*\})? 1(?:\.0)?/)
      expect(body).to match(/chatwoot_sidekiq_scrape_success(?:\{[^}]*\})? 1(?:\.0)?/)
      expect(body).to match(/chatwoot_sidekiq_processed(?:\{[^}]*\})? 10(?:\.0)?/)
      expect(body).to match(/chatwoot_sidekiq_failed(?:\{[^}]*\})? 2(?:\.0)?/)
      expect(body).to match(/chatwoot_sidekiq_enqueued(?:\{[^}]*\})? 3(?:\.0)?/)
      expect(body).to match(/chatwoot_sidekiq_retry_size(?:\{[^}]*\})? 1(?:\.0)?/)
      expect(body).to match(/chatwoot_sidekiq_dead_size(?:\{[^}]*\})? 4(?:\.0)?/)
      expect(body).to match(/chatwoot_sidekiq_workers(?:\{[^}]*\})? 5(?:\.0)?/)
      expect(body).to match(/chatwoot_sidekiq_queue_latency_seconds(?:\{[^}]*\})? 1\.5/)
      expect(body).not_to include('_total')
    end

    it 'drops stale Sidekiq gauges after a collect failure' do
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
      allow(Sidekiq::Queue).to receive(:all).and_return([])

      described_class.text
      allow(Sidekiq::Stats).to receive(:new).and_raise(StandardError, 'redis down')

      body = described_class.text

      expect(body).to match(/chatwoot_up(?:\{[^}]*\})? 1(?:\.0)?/)
      expect(body).to match(/chatwoot_sidekiq_scrape_success(?:\{[^}]*\})? 0(?:\.0)?/)
      expect(body).not_to include('chatwoot_sidekiq_processed')
      expect(body).not_to include('chatwoot_sidekiq_enqueued')
      expect(body).not_to include('chatwoot_sidekiq_queue_latency_seconds')
    end
  end
end
