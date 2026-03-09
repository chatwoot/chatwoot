class StickerCacheMonitorService
  METRICS_CACHE_KEY = 'sticker_cache_metrics'
  METRICS_TTL = 24.hours

  class << self
    def get_cache_stats
      {
        giphy: get_giphy_stats,
        whatsapp_media: get_whatsapp_media_stats,
        custom_stickers: get_custom_stickers_stats,
        overall: calculate_overall_stats
      }
    end

    def reset_cache_stats
      Rails.cache.delete_matched('*_cache_hit')
      Rails.cache.delete_matched('*_cache_miss')
      Rails.cache.delete_matched('*_cache_error')
      Rails.cache.delete_matched('*_cache_packs_*')
      Rails.logger.info 'StickerCacheMonitorService: Reset all cache statistics'
    end

    def warm_all_caches
      Rails.logger.info 'StickerCacheMonitorService: Starting cache warming process'
      
      # Warm Giphy cache
      giphy_service = GiphyService.new
      giphy_service.warm_cache
      
      # Warm custom stickers cache for all accounts
      warm_custom_stickers_cache
      
      Rails.logger.info 'StickerCacheMonitorService: Cache warming completed'
    end

    def cache_health_check
      health_status = {
        redis_available: redis_available?,
        cache_hit_rate: calculate_overall_hit_rate,
        timestamp: Time.current.iso8601
      }

      # Log warning if hit rate is too low
      if health_status[:cache_hit_rate] < 0.5
        Rails.logger.warn "Low cache hit rate detected: #{health_status[:cache_hit_rate]}"
      end

      health_status
    end

    private

    def get_giphy_stats
      hits = Rails.cache.read('giphy_cache_hit') || 0
      misses = Rails.cache.read('giphy_cache_miss') || 0
      errors = Rails.cache.read('giphy_cache_error') || 0
      
      total = hits + misses
      hit_rate = total > 0 ? (hits.to_f / total).round(3) : 0

      {
        hits: hits,
        misses: misses,
        errors: errors,
        hit_rate: hit_rate,
        total_requests: total
      }
    end

    def get_whatsapp_media_stats
      hits = Rails.cache.read('whatsapp_media_cache_hit') || 0
      misses = Rails.cache.read('whatsapp_media_cache_miss') || 0
      errors = Rails.cache.read('whatsapp_media_cache_error') || 0
      
      total = hits + misses
      hit_rate = total > 0 ? (hits.to_f / total).round(3) : 0

      {
        hits: hits,
        misses: misses,
        errors: errors,
        hit_rate: hit_rate,
        total_requests: total
      }
    end

    def get_custom_stickers_stats
      hits = Rails.cache.read('sticker_service_cache_hit') || 0
      misses = Rails.cache.read('sticker_service_cache_miss') || 0
      errors = Rails.cache.read('sticker_service_cache_error') || 0
      packs_hits = Rails.cache.read('sticker_service_cache_packs_hit') || 0
      packs_misses = Rails.cache.read('sticker_service_cache_packs_miss') || 0
      packs_errors = Rails.cache.read('sticker_service_cache_packs_error') || 0
      
      total_stickers = hits + misses
      total_packs = packs_hits + packs_misses
      
      stickers_hit_rate = total_stickers > 0 ? (hits.to_f / total_stickers).round(3) : 0
      packs_hit_rate = total_packs > 0 ? (packs_hits.to_f / total_packs).round(3) : 0

      {
        stickers: {
          hits: hits,
          misses: misses,
          errors: errors,
          hit_rate: stickers_hit_rate,
          total_requests: total_stickers
        },
        packs: {
          hits: packs_hits,
          misses: packs_misses,
          errors: packs_errors,
          hit_rate: packs_hit_rate,
          total_requests: total_packs
        }
      }
    end

    def calculate_overall_stats
      giphy_stats = get_giphy_stats
      media_stats = get_whatsapp_media_stats
      sticker_stats = get_custom_stickers_stats

      total_hits = giphy_stats[:hits] + media_stats[:hits] + 
                   sticker_stats[:stickers][:hits] + sticker_stats[:packs][:hits]
      
      total_requests = giphy_stats[:total_requests] + media_stats[:total_requests] + 
                       sticker_stats[:stickers][:total_requests] + sticker_stats[:packs][:total_requests]
      
      overall_hit_rate = total_requests > 0 ? (total_hits.to_f / total_requests).round(3) : 0

      {
        total_hits: total_hits,
        total_requests: total_requests,
        overall_hit_rate: overall_hit_rate
      }
    end

    def calculate_overall_hit_rate
      calculate_overall_stats[:overall_hit_rate]
    end

    def redis_available?
      Rails.cache.write('health_check', 'ok', expires_in: 1.second)
      Rails.cache.read('health_check') == 'ok'
    rescue StandardError
      false
    end

    def warm_custom_stickers_cache
      # Warm cache for accounts that have custom stickers
      Account.joins(:attachments)
             .where(attachments: { file_type: :image })
             .where("attachments.meta->>'sticker_type' = ?", 'custom')
             .distinct
             .find_each do |account|
        
        Rails.logger.info "Warming custom stickers cache for account #{account.id}"
        sticker_service = StickerService.new(account)
        
        # Warm packs cache
        sticker_service.custom_sticker_packs
        
        # Warm stickers cache for each pack
        sticker_service.custom_sticker_packs.each do |pack|
          sticker_service.custom_stickers(pack[:name])
        end
        
        # Warm all stickers cache
        sticker_service.custom_stickers
      end
    rescue StandardError => e
      Rails.logger.error "Error warming custom stickers cache: #{e.message}"
    end
  end
end