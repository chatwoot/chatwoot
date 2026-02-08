# frozen_string_literal: true

class Api::V1::Accounts::StickerPerformanceController < Api::V1::Accounts::BaseController
  before_action :check_authorization

  def index
    date = parse_date_param
    
    report = StickerPerformanceMetricsService.instance.get_performance_report(
      date: date,
      account_id: Current.account.id
    )
    
    render json: {
      performance_report: report,
      account_id: Current.account.id
    }
  end

  def usage_stats
    date = parse_date_param
    date_range = parse_date_range_param
    
    if date_range
      stats = {}
      date_range.each do |d|
        stats[d.strftime('%Y-%m-%d')] = StickerPerformanceMetricsService.instance.get_usage_stats(
          date: d,
          account_id: Current.account.id
        )
      end
    else
      stats = StickerPerformanceMetricsService.instance.get_usage_stats(
        date: date,
        account_id: Current.account.id
      )
    end
    
    render json: {
      usage_stats: stats,
      date: date&.strftime('%Y-%m-%d'),
      date_range: date_range&.map { |d| d.strftime('%Y-%m-%d') }
    }
  end

  def cache_performance
    date = parse_date_param
    
    cache_stats = StickerPerformanceMetricsService.instance.get_cache_stats(date: date)
    
    render json: {
      cache_stats: cache_stats,
      date: date.strftime('%Y-%m-%d'),
      summary: {
        total_cache_types: cache_stats.keys.length,
        overall_hit_rate: calculate_overall_hit_rate(cache_stats),
        best_performing_cache: find_best_cache(cache_stats),
        worst_performing_cache: find_worst_cache(cache_stats)
      }
    }
  end

  def api_performance
    date = parse_date_param
    
    api_stats = StickerPerformanceMetricsService.instance.get_api_performance_stats(date: date)
    
    render json: {
      api_performance: api_stats,
      date: date.strftime('%Y-%m-%d'),
      summary: {
        total_apis: api_stats.keys.length,
        overall_success_rate: calculate_overall_success_rate(api_stats),
        fastest_api: find_fastest_api(api_stats),
        slowest_api: find_slowest_api(api_stats)
      }
    }
  end

  def benchmark_image_processing
    return render_unauthorized unless Current.user.administrator?
    
    # Create a test image for benchmarking
    test_file = create_test_image_file
    
    begin
      benchmark_result = StickerImageOptimizerService.benchmark_processing(
        test_file,
        iterations: params[:iterations]&.to_i || 5
      )
      
      render json: {
        benchmark_result: benchmark_result,
        test_conditions: {
          iterations: params[:iterations]&.to_i || 5,
          test_image_size: test_file.size,
          timestamp: Time.current.iso8601
        }
      }
    ensure
      test_file.close! if test_file.respond_to?(:close!)
    end
  end

  def system_health
    return render_unauthorized unless Current.user.administrator?
    
    health_data = {
      redis_status: check_redis_health,
      image_processing_status: check_image_processing_health,
      external_apis_status: check_external_apis_health,
      cache_memory_usage: get_cache_memory_usage,
      timestamp: Time.current.iso8601
    }
    
    render json: {
      system_health: health_data,
      overall_status: determine_overall_health(health_data)
    }
  end

  private

  def check_authorization
    authorize :sticker_performance, :show?
  end

  def parse_date_param
    if params[:date].present?
      Date.parse(params[:date])
    else
      Date.current
    end
  rescue ArgumentError
    Date.current
  end

  def parse_date_range_param
    return nil unless params[:start_date].present? && params[:end_date].present?
    
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])
    
    # Limit range to 30 days for performance
    if (end_date - start_date).to_i > 30
      end_date = start_date + 30.days
    end
    
    (start_date..end_date).to_a
  rescue ArgumentError
    nil
  end

  def calculate_overall_hit_rate(cache_stats)
    return 0 if cache_stats.empty?
    
    total_hits = cache_stats.values.sum { |stats| stats[:hits] }
    total_requests = cache_stats.values.sum { |stats| stats[:total] }
    
    return 0 if total_requests.zero?
    
    (total_hits.to_f / total_requests * 100).round(2)
  end

  def find_best_cache(cache_stats)
    return nil if cache_stats.empty?
    
    cache_stats.max_by { |_name, stats| stats[:hit_rate] }&.first
  end

  def find_worst_cache(cache_stats)
    return nil if cache_stats.empty?
    
    cache_stats.min_by { |_name, stats| stats[:hit_rate] }&.first
  end

  def calculate_overall_success_rate(api_stats)
    return 0 if api_stats.empty?
    
    total_success = api_stats.values.sum { |stats| stats[:success_count] }
    total_requests = api_stats.values.sum { |stats| stats[:total_requests] }
    
    return 0 if total_requests.zero?
    
    (total_success.to_f / total_requests * 100).round(2)
  end

  def find_fastest_api(api_stats)
    return nil if api_stats.empty?
    
    api_stats.min_by { |_name, stats| stats[:avg_response_time] }&.first
  end

  def find_slowest_api(api_stats)
    return nil if api_stats.empty?
    
    api_stats.max_by { |_name, stats| stats[:avg_response_time] }&.first
  end

  def create_test_image_file
    # Create a simple test image in memory
    require 'vips'
    
    temp_file = Tempfile.new(['benchmark_test', '.png'])
    
    # Create a 200x200 test image using libvips
    image = Vips::Image.black(200, 200)
    image.pngsave(temp_file.path)
    
    # Return as uploaded file
    ActionDispatch::Http::UploadedFile.new(
      tempfile: temp_file,
      filename: 'benchmark_test.png',
      type: 'image/png'
    )
  end

  def check_redis_health
    begin
      Redis.current.ping == 'PONG' ? 'healthy' : 'unhealthy'
    rescue StandardError => e
      Rails.logger.error "Redis health check failed: #{e.message}"
      'unhealthy'
    end
  end

  def check_image_processing_health
    begin
      # Test libvips availability
      require 'vips'
      Vips.version_string
      'healthy'
    rescue StandardError => e
      Rails.logger.error "Image processing health check failed: #{e.message}"
      'unhealthy'
    end
  end

  def check_external_apis_health
    # This would check Giphy API and WhatsApp API health
    # For now, return a placeholder
    {
      giphy_api: 'unknown',
      whatsapp_api: 'unknown'
    }
  end

  def get_cache_memory_usage
    begin
      info = Redis.current.info('memory')
      {
        used_memory: info['used_memory'],
        used_memory_human: info['used_memory_human'],
        used_memory_peak: info['used_memory_peak'],
        used_memory_peak_human: info['used_memory_peak_human']
      }
    rescue StandardError => e
      Rails.logger.error "Cache memory usage check failed: #{e.message}"
      { error: 'Unable to retrieve memory usage' }
    end
  end

  def determine_overall_health(health_data)
    unhealthy_services = health_data.values.count { |status| status == 'unhealthy' }
    
    if unhealthy_services.zero?
      'healthy'
    elsif unhealthy_services <= 1
      'degraded'
    else
      'unhealthy'
    end
  end

  def render_unauthorized
    render json: { error: 'Unauthorized' }, status: :unauthorized
  end
end