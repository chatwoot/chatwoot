# frozen_string_literal: true

namespace :stickers do
  namespace :performance do
    desc 'Generate performance report for sticker usage'
    task :report, [:account_id, :date] => :environment do |_task, args|
      account_id = args[:account_id]
      date = args[:date] ? Date.parse(args[:date]) : Date.current
      
      puts "Generating sticker performance report for #{date}..."
      
      metrics_service = StickerPerformanceMetricsService.instance
      report = metrics_service.get_performance_report(
        date: date,
        account_id: account_id&.to_i
      )
      
      puts "\n=== STICKER PERFORMANCE REPORT ==="
      puts "Date: #{report[:date]}"
      puts "Account ID: #{account_id || 'All accounts'}"
      puts "Generated at: #{report[:generated_at]}"
      
      puts "\n--- Usage Statistics ---"
      if report[:usage_stats].any?
        report[:usage_stats].each do |provider, count|
          puts "#{provider.capitalize}: #{count} stickers sent"
        end
        total_usage = report[:usage_stats].values.sum
        puts "Total: #{total_usage} stickers sent"
      else
        puts "No sticker usage recorded for this date"
      end
      
      puts "\n--- Cache Performance ---"
      if report[:cache_stats].any?
        report[:cache_stats].each do |cache_type, stats|
          puts "#{cache_type}:"
          puts "  Hit rate: #{stats[:hit_rate]}%"
          puts "  Hits: #{stats[:hits]}, Misses: #{stats[:misses]}"
          puts "  Total requests: #{stats[:total]}"
        end
      else
        puts "No cache statistics available for this date"
      end
      
      puts "\n--- API Performance ---"
      if report[:api_performance].any?
        report[:api_performance].each do |api_name, stats|
          puts "#{api_name}:"
          puts "  Success rate: #{stats[:success_rate]}%"
          puts "  Average response time: #{stats[:avg_response_time]}ms"
          puts "  Total requests: #{stats[:total_requests]}"
          puts "  Successful: #{stats[:success_count]}, Failed: #{stats[:failure_count]}"
        end
      else
        puts "No API performance statistics available for this date"
      end
      
      puts "\n=== END REPORT ==="
    end

    desc 'Benchmark image processing performance'
    task :benchmark_image_processing, [:iterations] => :environment do |_task, args|
      iterations = args[:iterations]&.to_i || 5
      
      puts "Running image processing benchmark with #{iterations} iterations..."
      
      # Create a test image file
      require 'mini_magick'
      temp_file = Tempfile.new(['benchmark_test', '.png'])
      
      begin
        # Create a 200x200 test image
        image = MiniMagick::Image.open('logo:')
        image.resize '200x200'
        image.format 'png'
        image.write(temp_file.path)
        
        # Create uploaded file object
        test_file = ActionDispatch::Http::UploadedFile.new(
          tempfile: temp_file,
          filename: 'benchmark_test.png',
          type: 'image/png'
        )
        
        # Run benchmark
        result = StickerImageOptimizerService.benchmark_processing(test_file, iterations: iterations)
        
        puts "\n=== IMAGE PROCESSING BENCHMARK RESULTS ==="
        puts "Iterations: #{result[:iterations]}"
        puts "Successful: #{result[:successful]}"
        puts "Failed: #{result[:failed]}"
        
        if result[:successful] > 0
          puts "Average processing time: #{result[:avg_processing_time]}ms"
          puts "Min processing time: #{result[:min_processing_time]}ms"
          puts "Max processing time: #{result[:max_processing_time]}ms"
          puts "Average compression ratio: #{result[:avg_compression_ratio]}%"
        else
          puts "Error: #{result[:error]}"
        end
        
        puts "=== END BENCHMARK ==="
        
      ensure
        temp_file.close! if temp_file
      end
    end

    desc 'Clean up old performance metrics'
    task :cleanup_metrics, [:days_to_keep] => :environment do |_task, args|
      days_to_keep = args[:days_to_keep]&.to_i || 30
      cutoff_date = Date.current - days_to_keep.days
      
      puts "Cleaning up performance metrics older than #{days_to_keep} days (before #{cutoff_date})..."
      
      redis = Redis.current
      metrics_prefix = 'sticker_metrics'
      
      # Get all metric keys
      all_keys = redis.keys("#{metrics_prefix}:*")
      deleted_count = 0
      
      all_keys.each do |key|
        # Extract date from key (assuming format includes YYYY-MM-DD)
        date_match = key.match(/(\d{4}-\d{2}-\d{2})/)
        next unless date_match
        
        key_date = Date.parse(date_match[1])
        if key_date < cutoff_date
          redis.del(key)
          deleted_count += 1
        end
      rescue Date::Error
        # Skip keys with invalid date formats
        next
      end
      
      puts "Cleaned up #{deleted_count} old metric keys"
    end

    desc 'Warm up sticker caches'
    task :warm_cache => :environment do
      puts "Warming up sticker caches..."
      
      # Warm up Giphy cache
      puts "Warming Giphy cache..."
      giphy_service = GiphyService.new
      giphy_service.warm_cache
      
      puts "Cache warming completed"
    end

    desc 'Monitor system health'
    task :health_check => :environment do
      puts "Checking sticker system health..."
      
      health_status = {
        redis: check_redis_health,
        image_processing: check_image_processing_health,
        giphy_api: check_giphy_api_health
      }
      
      puts "\n=== SYSTEM HEALTH CHECK ==="
      health_status.each do |component, status|
        status_icon = status == 'healthy' ? '✓' : '✗'
        puts "#{status_icon} #{component.to_s.humanize}: #{status}"
      end
      
      overall_health = health_status.values.all? { |status| status == 'healthy' } ? 'healthy' : 'degraded'
      puts "\nOverall system health: #{overall_health}"
      puts "=== END HEALTH CHECK ==="
    end

    desc 'Export performance data to CSV'
    task :export_csv, [:account_id, :start_date, :end_date, :output_file] => :environment do |_task, args|
      account_id = args[:account_id]&.to_i
      start_date = args[:start_date] ? Date.parse(args[:start_date]) : Date.current - 7.days
      end_date = args[:end_date] ? Date.parse(args[:end_date]) : Date.current
      output_file = args[:output_file] || "sticker_performance_#{start_date}_to_#{end_date}.csv"
      
      puts "Exporting performance data from #{start_date} to #{end_date}..."
      
      require 'csv'
      metrics_service = StickerPerformanceMetricsService.instance
      
      CSV.open(output_file, 'w') do |csv|
        # Write headers
        csv << ['Date', 'Account ID', 'Provider', 'Usage Count', 'Cache Hit Rate', 'API Success Rate', 'Avg Response Time']
        
        (start_date..end_date).each do |date|
          report = metrics_service.get_performance_report(date: date, account_id: account_id)
          
          report[:usage_stats].each do |provider, count|
            cache_stats = report[:cache_stats]["#{provider}_search"] || {}
            api_stats = report[:api_performance]["#{provider}_api"] || {}
            
            csv << [
              date.strftime('%Y-%m-%d'),
              account_id || 'All',
              provider,
              count,
              cache_stats[:hit_rate] || 0,
              api_stats[:success_rate] || 0,
              api_stats[:avg_response_time] || 0
            ]
          end
        end
      end
      
      puts "Performance data exported to #{output_file}"
    end

    private

    def check_redis_health
      Redis.current.ping == 'PONG' ? 'healthy' : 'unhealthy'
    rescue StandardError
      'unhealthy'
    end

    def check_image_processing_health
      MiniMagick::Tool::Identify.new.version
      'healthy'
    rescue StandardError
      'unhealthy'
    end

    def check_giphy_api_health
      return 'not_configured' unless ENV['GIPHY_API_KEY'].present?
      
      # Simple API test
      giphy_service = GiphyService.new
      result = giphy_service.search_or_trending('test')
      result.is_a?(Array) ? 'healthy' : 'unhealthy'
    rescue StandardError
      'unhealthy'
    end
  end
end