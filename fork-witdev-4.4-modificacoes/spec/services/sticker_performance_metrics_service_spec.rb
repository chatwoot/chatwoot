# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StickerPerformanceMetricsService, type: :service do
  let(:service) { described_class.instance }
  let(:redis) { Redis.current }
  let(:account_id) { 1 }
  let(:user_id) { 1 }
  let(:date_key) { Date.current.strftime('%Y-%m-%d') }

  before do
    # Clear Redis test data
    redis.flushdb
  end

  after do
    redis.flushdb
  end

  describe '#track_sticker_usage' do
    it 'tracks sticker usage metrics correctly' do
      service.track_sticker_usage(
        provider: 'giphy',
        account_id: account_id,
        user_id: user_id,
        response_time: 150.5
      )

      # Check daily usage
      daily_usage = redis.hgetall("sticker_metrics:daily_usage:#{date_key}")
      expect(daily_usage['giphy']).to eq('1')

      # Check account usage
      account_usage = redis.hgetall("sticker_metrics:account_usage:#{account_id}:#{date_key}")
      expect(account_usage['giphy']).to eq('1')

      # Check user usage
      user_usage = redis.hgetall("sticker_metrics:user_usage:#{user_id}:#{date_key}")
      expect(user_usage['giphy']).to eq('1')

      # Check response time
      response_times = redis.lrange("sticker_metrics:response_times:giphy:#{date_key}", 0, -1)
      expect(response_times).to include('150.5')
    end

    it 'increments existing counters' do
      # Track first usage
      service.track_sticker_usage(provider: 'giphy', account_id: account_id, user_id: user_id)
      
      # Track second usage
      service.track_sticker_usage(provider: 'giphy', account_id: account_id, user_id: user_id)

      daily_usage = redis.hgetall("sticker_metrics:daily_usage:#{date_key}")
      expect(daily_usage['giphy']).to eq('2')
    end

    it 'tracks different providers separately' do
      service.track_sticker_usage(provider: 'giphy', account_id: account_id, user_id: user_id)
      service.track_sticker_usage(provider: 'custom', account_id: account_id, user_id: user_id)

      daily_usage = redis.hgetall("sticker_metrics:daily_usage:#{date_key}")
      expect(daily_usage['giphy']).to eq('1')
      expect(daily_usage['custom']).to eq('1')
    end
  end

  describe '#track_cache_hit' do
    it 'tracks cache hits correctly' do
      service.track_cache_hit(cache_type: 'giphy_search', hit: true)
      service.track_cache_hit(cache_type: 'giphy_search', hit: false)

      hits = redis.hgetall("sticker_metrics:cache_hits:#{date_key}")
      misses = redis.hgetall("sticker_metrics:cache_misses:#{date_key}")

      expect(hits['giphy_search']).to eq('1')
      expect(misses['giphy_search']).to eq('1')
    end
  end

  describe '#track_api_performance' do
    it 'tracks API performance metrics' do
      service.track_api_performance(
        api_name: 'giphy_api',
        response_time: 250.0,
        success: true
      )

      service.track_api_performance(
        api_name: 'giphy_api',
        response_time: 300.0,
        success: false
      )

      # Check response times
      response_times = redis.lrange("sticker_metrics:api_response_times:giphy_api:#{date_key}", 0, -1)
      expect(response_times).to include('250.0', '300.0')

      # Check success/failure counts
      success_data = redis.hgetall("sticker_metrics:api_success:#{date_key}")
      failure_data = redis.hgetall("sticker_metrics:api_failures:#{date_key}")

      expect(success_data['giphy_api']).to eq('1')
      expect(failure_data['giphy_api']).to eq('1')
    end
  end

  describe '#get_usage_stats' do
    before do
      service.track_sticker_usage(provider: 'giphy', account_id: account_id, user_id: user_id)
      service.track_sticker_usage(provider: 'giphy', account_id: account_id, user_id: user_id)
      service.track_sticker_usage(provider: 'custom', account_id: account_id, user_id: user_id)
    end

    it 'returns daily usage stats' do
      stats = service.get_usage_stats

      expect(stats['giphy']).to eq(2)
      expect(stats['custom']).to eq(1)
    end

    it 'returns account-specific usage stats' do
      stats = service.get_usage_stats(account_id: account_id)

      expect(stats['giphy']).to eq(2)
      expect(stats['custom']).to eq(1)
    end
  end

  describe '#get_cache_stats' do
    before do
      service.track_cache_hit(cache_type: 'giphy_search', hit: true)
      service.track_cache_hit(cache_type: 'giphy_search', hit: true)
      service.track_cache_hit(cache_type: 'giphy_search', hit: false)
      service.track_cache_hit(cache_type: 'whatsapp_media', hit: true)
    end

    it 'returns cache performance statistics' do
      stats = service.get_cache_stats

      expect(stats['giphy_search']).to include(
        hits: 2,
        misses: 1,
        total: 3,
        hit_rate: 66.67
      )

      expect(stats['whatsapp_media']).to include(
        hits: 1,
        misses: 0,
        total: 1,
        hit_rate: 100.0
      )
    end
  end

  describe '#get_api_performance_stats' do
    before do
      service.track_api_performance(api_name: 'giphy_api', response_time: 100.0, success: true)
      service.track_api_performance(api_name: 'giphy_api', response_time: 200.0, success: true)
      service.track_api_performance(api_name: 'giphy_api', response_time: 300.0, success: false)
    end

    it 'returns API performance statistics' do
      stats = service.get_api_performance_stats

      expect(stats['giphy_api']).to include(
        success_count: 2,
        failure_count: 1,
        total_requests: 3,
        success_rate: 66.67,
        avg_response_time: 200.0,
        max_response_time: 300.0,
        min_response_time: 100.0
      )
    end
  end

  describe '#get_performance_report' do
    before do
      service.track_sticker_usage(provider: 'giphy', account_id: account_id, user_id: user_id)
      service.track_cache_hit(cache_type: 'giphy_search', hit: true)
      service.track_api_performance(api_name: 'giphy_api', response_time: 150.0, success: true)
    end

    it 'returns comprehensive performance report' do
      report = service.get_performance_report

      expect(report).to include(
        :date,
        :usage_stats,
        :cache_stats,
        :api_performance,
        :generated_at
      )

      expect(report[:usage_stats]['giphy']).to eq(1)
      expect(report[:cache_stats]['giphy_search'][:hit_rate]).to eq(100.0)
      expect(report[:api_performance]['giphy_api'][:success_rate]).to eq(100.0)
    end

    it 'returns account-specific report when account_id provided' do
      report = service.get_performance_report(account_id: account_id)

      expect(report[:usage_stats]['giphy']).to eq(1)
    end
  end
end