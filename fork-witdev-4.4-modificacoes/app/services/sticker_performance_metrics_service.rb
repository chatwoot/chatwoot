# frozen_string_literal: true

class StickerPerformanceMetricsService
  include Singleton

  METRICS_KEY_PREFIX = 'sticker_metrics'
  METRICS_TTL = 7.days

  def initialize
    # Simplified initialization without Redis pool for now
  end

  def track_sticker_usage(*args, **kwargs)
    # Handle both positional and keyword arguments
    if kwargs.any?
      # Called with keyword arguments (from SendStickerService)
      provider = kwargs[:provider] || 'unknown'
      account_id = kwargs[:account_id] || 'unknown'
      response_time = kwargs[:response_time] || 0
      Rails.logger.info "Sticker usage tracked: provider=#{provider}, account_id=#{account_id}, response_time=#{response_time}ms"
    else
      # Called with positional arguments (legacy)
      sticker_id, user_id, account_id = args
      Rails.logger.info "Sticker usage tracked: sticker_id=#{sticker_id}, user_id=#{user_id}, account_id=#{account_id}"
    end
  end

  def track_search_query(query, results_count, user_id, account_id)
    # Simplified tracking - just log for now
    Rails.logger.info "Search query tracked: query=#{query}, results=#{results_count}, user_id=#{user_id}, account_id=#{account_id}"
  end

  def get_popular_stickers(account_id, limit = 10)
    # Return empty array for now - can be implemented later
    []
  end

  def get_user_recent_stickers(user_id, limit = 10)
    # Return empty array for now - can be implemented later
    []
  end

  def track_cache_hit(*args, **kwargs)
    # Handle both positional and keyword arguments
    if kwargs.any?
      # Called with keyword arguments (from SendStickerService)
      cache_type = kwargs[:cache_type] || 'unknown'
      hit = kwargs[:hit] || false
      Rails.logger.info "Cache tracked: type=#{cache_type}, hit=#{hit}"
    else
      # Called with positional arguments (legacy)
      key, user_id, account_id = args
      Rails.logger.info "Cache hit tracked: key=#{key}, user_id=#{user_id}, account_id=#{account_id}"
    end
  end

  def track_cache_miss(key, user_id, account_id)
    # Simplified tracking - just log for now
    Rails.logger.info "Cache miss tracked: key=#{key}, user_id=#{user_id}, account_id=#{account_id}"
  end

  def track_api_performance(*args, **kwargs)
    # Handle both positional and keyword arguments
    if kwargs.any?
      # Called with keyword arguments (from SendStickerService)
      api_name = kwargs[:api_name] || 'unknown'
      response_time = kwargs[:response_time] || 0
      success = kwargs[:success] || false
      Rails.logger.info "API performance tracked: api=#{api_name}, duration=#{response_time}ms, success=#{success}"
    else
      # Called with positional arguments (legacy)
      operation, duration, success, user_id, account_id = args
      Rails.logger.info "API performance tracked: operation=#{operation}, duration=#{duration}ms, success=#{success}, user_id=#{user_id}, account_id=#{account_id}"
    end
  end

  def track_error(error_code, error_message, context, user_id, account_id)
    # Simplified tracking - just log for now
    Rails.logger.error "Error tracked: code=#{error_code}, message=#{error_message}, context=#{context}, user_id=#{user_id}, account_id=#{account_id}"
  end

  def track_media_fetch(url, success, duration, user_id, account_id)
    # Simplified tracking - just log for now
    Rails.logger.info "Media fetch tracked: url=#{url}, success=#{success}, duration=#{duration}ms, user_id=#{user_id}, account_id=#{account_id}"
  end

  def track_whatsapp_api_call(endpoint, success, duration, user_id, account_id)
    # Simplified tracking - just log for now
    Rails.logger.info "WhatsApp API call tracked: endpoint=#{endpoint}, success=#{success}, duration=#{duration}ms, user_id=#{user_id}, account_id=#{account_id}"
  end

  private

  def ensure_redis_connection
    # Simplified - no Redis connection for now
  end
end