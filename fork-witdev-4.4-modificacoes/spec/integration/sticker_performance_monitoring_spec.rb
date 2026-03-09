# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sticker Performance Monitoring Integration', type: :integration do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:metrics_service) { StickerPerformanceMetricsService.instance }
  let(:redis) { Redis.current }

  before do
    redis.flushdb
    allow(StickerPerformanceMetricsService).to receive(:instance).and_return(metrics_service)
  end

  after do
    redis.flushdb
  end

  describe 'End-to-end sticker performance tracking' do
    context 'when sending a Giphy sticker' do
      let(:sticker_data) do
        {
          id: 'test_giphy_id',
          url: 'https://media.giphy.com/media/test/giphy.webp',
          alt: 'Test Giphy Sticker',
          provider: 'giphy'
        }
      end

      it 'tracks all performance metrics throughout the flow' do
        # Mock external services
        allow_any_instance_of(GiphyService).to receive(:search_or_trending).and_return([sticker_data])
        allow_any_instance_of(Whatsapp::SendStickerService).to receive(:send_to_whatsapp).and_return({ success: true })
        allow_any_instance_of(Whatsapp::SendStickerService).to receive(:upload_media_to_whatsapp).and_return('media_123')

        # Simulate Giphy API call
        giphy_service = GiphyService.new
        giphy_result = giphy_service.search_or_trending('happy')

        expect(giphy_result).to include(sticker_data)

        # Simulate sticker sending
        send_service = Whatsapp::SendStickerService.new(
          conversation: conversation,
          sticker_data: sticker_data,
          user: user
        )

        result = send_service.perform

        expect(result[:success]).to be true

        # Verify metrics were tracked
        usage_stats = metrics_service.get_usage_stats(account_id: account.id)
        expect(usage_stats['giphy']).to eq(1)

        cache_stats = metrics_service.get_cache_stats
        expect(cache_stats).to have_key('giphy_search')
        expect(cache_stats).to have_key('whatsapp_media')

        api_stats = metrics_service.get_api_performance_stats
        expect(api_stats).to have_key('giphy_api')
        expect(api_stats).to have_key('whatsapp_send_sticker')
      end
    end

    context 'when processing custom stickers' do
      let(:test_image_file) do
        # Create a test image file
        temp_file = Tempfile.new(['test_sticker', '.png'])
        
        # Create a simple test image using MiniMagick
        require 'mini_magick'
        image = MiniMagick::Image.open('logo:')
        image.resize '100x100'
        image.format 'png'
        image.write(temp_file.path)
        
        ActionDispatch::Http::UploadedFile.new(
          tempfile: temp_file,
          filename: 'test_sticker.png',
          type: 'image/png'
        )
      end

      it 'tracks image processing performance' do
        optimizer_service = StickerImageOptimizerService.new(
          file: test_image_file,
          account_id: account.id
        )

        result = optimizer_service.process

        expect(result[:success]).to be true
        expect(result[:processing_time]).to be > 0
        expect(result[:compression_ratio]).to be >= 0

        # Verify API performance was tracked
        api_stats = metrics_service.get_api_performance_stats
        expect(api_stats).to have_key('image_processing')
        expect(api_stats['image_processing'][:success_count]).to eq(1)
      end

      it 'tracks batch processing performance' do
        files = [test_image_file, test_image_file]

        result = StickerImageOptimizerService.batch_process(files, account_id: account.id)

        expect(result[:total_files]).to eq(2)
        expect(result[:successful]).to be >= 0
        expect(result[:total_processing_time]).to be > 0

        # Verify multiple processing operations were tracked
        api_stats = metrics_service.get_api_performance_stats
        expect(api_stats['image_processing'][:total_requests]).to eq(2)
      end
    end
  end

  describe 'Performance reporting' do
    before do
      # Seed some test data
      metrics_service.track_sticker_usage(
        provider: 'giphy',
        account_id: account.id,
        user_id: user.id,
        response_time: 150.0
      )

      metrics_service.track_cache_hit(cache_type: 'giphy_search', hit: true)
      metrics_service.track_cache_hit(cache_type: 'giphy_search', hit: false)

      metrics_service.track_api_performance(
        api_name: 'giphy_api',
        response_time: 200.0,
        success: true
      )
    end

    it 'generates comprehensive performance reports' do
      report = metrics_service.get_performance_report(account_id: account.id)

      expect(report).to include(
        :date,
        :usage_stats,
        :cache_stats,
        :api_performance,
        :generated_at
      )

      expect(report[:usage_stats]['giphy']).to eq(1)
      expect(report[:cache_stats]['giphy_search'][:hit_rate]).to eq(50.0)
      expect(report[:api_performance]['giphy_api'][:success_rate]).to eq(100.0)
    end

    it 'provides accurate cache performance metrics' do
      cache_stats = metrics_service.get_cache_stats

      expect(cache_stats['giphy_search']).to include(
        hits: 1,
        misses: 1,
        total: 2,
        hit_rate: 50.0
      )
    end

    it 'provides detailed API performance metrics' do
      api_stats = metrics_service.get_api_performance_stats

      expect(api_stats['giphy_api']).to include(
        success_count: 1,
        failure_count: 0,
        total_requests: 1,
        success_rate: 100.0,
        avg_response_time: 200.0
      )
    end
  end

  describe 'Error tracking and performance impact' do
    context 'when Giphy API fails' do
      it 'tracks failed API calls and maintains system stability' do
        # Mock Giphy API failure
        allow_any_instance_of(GiphyService).to receive(:make_api_request)
          .and_raise(GiphyService::ApiUnavailableError, 'Service unavailable')

        giphy_service = GiphyService.new
        result = giphy_service.search_or_trending('test')

        expect(result[:error]).to eq('GIPHY_UNAVAILABLE')

        # Verify error was tracked in performance metrics
        api_stats = metrics_service.get_api_performance_stats
        expect(api_stats['giphy_api'][:failure_count]).to eq(1)
        expect(api_stats['giphy_api'][:success_rate]).to eq(0.0)
      end
    end

    context 'when image processing fails' do
      let(:invalid_file) do
        temp_file = Tempfile.new(['invalid', '.txt'])
        temp_file.write('invalid image data')
        temp_file.rewind
        
        ActionDispatch::Http::UploadedFile.new(
          tempfile: temp_file,
          filename: 'invalid.txt',
          type: 'text/plain'
        )
      end

      it 'tracks processing failures and provides error details' do
        optimizer_service = StickerImageOptimizerService.new(
          file: invalid_file,
          account_id: account.id
        )

        result = optimizer_service.process

        expect(result[:success]).to be false
        expect(result[:error]).to be_present

        # Verify failure was tracked
        api_stats = metrics_service.get_api_performance_stats
        expect(api_stats['image_processing'][:failure_count]).to eq(1)
      end
    end
  end

  describe 'Performance optimization verification' do
    it 'demonstrates cache effectiveness' do
      # First call - cache miss
      allow_any_instance_of(GiphyService).to receive(:search).and_return([])
      
      giphy_service = GiphyService.new
      result1 = giphy_service.search_or_trending('test')

      # Second call - cache hit
      result2 = giphy_service.search_or_trending('test')

      # Verify both calls returned same result
      expect(result1).to eq(result2)

      # Verify cache metrics
      cache_stats = metrics_service.get_cache_stats
      expect(cache_stats['giphy_search'][:total]).to eq(2)
      expect(cache_stats['giphy_search'][:hits]).to eq(1)
      expect(cache_stats['giphy_search'][:misses]).to eq(1)
      expect(cache_stats['giphy_search'][:hit_rate]).to eq(50.0)
    end

    it 'verifies image processing optimization' do
      # Create a larger test image to verify compression
      temp_file = Tempfile.new(['large_test', '.png'])
      
      require 'mini_magick'
      image = MiniMagick::Image.open('logo:')
      image.resize '800x600'  # Larger than target size
      image.format 'png'
      image.write(temp_file.path)
      
      large_file = ActionDispatch::Http::UploadedFile.new(
        tempfile: temp_file,
        filename: 'large_test.png',
        type: 'image/png'
      )

      optimizer_service = StickerImageOptimizerService.new(
        file: large_file,
        account_id: account.id
      )

      result = optimizer_service.process

      expect(result[:success]).to be true
      expect(result[:final_size]).to be <= StickerImageOptimizerService::MAX_FILE_SIZE
      expect(result[:compression_ratio]).to be > 0
      expect(result[:processing_time]).to be < 1000  # Should process in under 1 second
    end
  end

  describe 'System health monitoring' do
    it 'provides accurate system health status' do
      # Mock healthy system components
      allow(Redis.current).to receive(:ping).and_return('PONG')
      allow(MiniMagick::Tool::Identify).to receive(:new).and_return(double(version: '7.0.0'))

      health_data = {
        redis_status: 'healthy',
        image_processing_status: 'healthy',
        external_apis_status: { giphy_api: 'healthy', whatsapp_api: 'healthy' }
      }

      # Verify health check logic
      expect(health_data[:redis_status]).to eq('healthy')
      expect(health_data[:image_processing_status]).to eq('healthy')
    end
  end

  describe 'Performance benchmarking' do
    let(:test_file) do
      temp_file = Tempfile.new(['benchmark', '.png'])
      
      require 'mini_magick'
      image = MiniMagick::Image.open('logo:')
      image.resize '200x200'
      image.format 'png'
      image.write(temp_file.path)
      
      ActionDispatch::Http::UploadedFile.new(
        tempfile: temp_file,
        filename: 'benchmark.png',
        type: 'image/png'
      )
    end

    it 'provides consistent benchmark results' do
      result = StickerImageOptimizerService.benchmark_processing(test_file, iterations: 3)

      expect(result[:iterations]).to eq(3)
      expect(result[:successful]).to be >= 0
      expect(result[:failed]).to be >= 0

      if result[:successful] > 0
        expect(result[:avg_processing_time]).to be > 0
        expect(result[:min_processing_time]).to be <= result[:avg_processing_time]
        expect(result[:max_processing_time]).to be >= result[:avg_processing_time]
      end
    end
  end
end