namespace :sticker_cache do
  desc 'Display sticker cache statistics'
  task stats: :environment do
    puts "\n=== Sticker Cache Statistics ==="
    puts "Generated at: #{Time.current}"
    puts "=" * 50

    stats = StickerCacheMonitorService.get_cache_stats

    # Giphy Stats
    puts "\n📊 Giphy API Cache:"
    puts "  Hits: #{stats[:giphy][:hits]}"
    puts "  Misses: #{stats[:giphy][:misses]}"
    puts "  Errors: #{stats[:giphy][:errors]}"
    puts "  Hit Rate: #{(stats[:giphy][:hit_rate] * 100).round(1)}%"
    puts "  Total Requests: #{stats[:giphy][:total_requests]}"

    # WhatsApp Media Stats
    puts "\n📱 WhatsApp Media Cache:"
    puts "  Hits: #{stats[:whatsapp_media][:hits]}"
    puts "  Misses: #{stats[:whatsapp_media][:misses]}"
    puts "  Errors: #{stats[:whatsapp_media][:errors]}"
    puts "  Hit Rate: #{(stats[:whatsapp_media][:hit_rate] * 100).round(1)}%"
    puts "  Total Requests: #{stats[:whatsapp_media][:total_requests]}"

    # Custom Stickers Stats
    puts "\n🎨 Custom Stickers Cache:"
    puts "  Stickers - Hits: #{stats[:custom_stickers][:stickers][:hits]}, Misses: #{stats[:custom_stickers][:stickers][:misses]}, Hit Rate: #{(stats[:custom_stickers][:stickers][:hit_rate] * 100).round(1)}%"
    puts "  Packs - Hits: #{stats[:custom_stickers][:packs][:hits]}, Misses: #{stats[:custom_stickers][:packs][:misses]}, Hit Rate: #{(stats[:custom_stickers][:packs][:hit_rate] * 100).round(1)}%"

    # Overall Stats
    puts "\n🎯 Overall Performance:"
    puts "  Total Hits: #{stats[:overall][:total_hits]}"
    puts "  Total Requests: #{stats[:overall][:total_requests]}"
    puts "  Overall Hit Rate: #{(stats[:overall][:overall_hit_rate] * 100).round(1)}%"

    # Health Check
    health = StickerCacheMonitorService.cache_health_check
    puts "\n🏥 Health Status:"
    puts "  Redis Available: #{health[:redis_available] ? '✅' : '❌'}"
    puts "  Cache Hit Rate: #{(health[:cache_hit_rate] * 100).round(1)}%"
    
    if health[:cache_hit_rate] < 0.5
      puts "  ⚠️  WARNING: Low cache hit rate detected!"
    elsif health[:cache_hit_rate] > 0.8
      puts "  ✅ Excellent cache performance!"
    end

    puts "\n" + "=" * 50
  end

  desc 'Reset all sticker cache statistics'
  task reset_stats: :environment do
    puts "Resetting sticker cache statistics..."
    StickerCacheMonitorService.reset_cache_stats
    puts "✅ Cache statistics reset successfully!"
  end

  desc 'Warm all sticker caches'
  task warm: :environment do
    puts "Starting cache warming process..."
    puts "This may take a few minutes depending on the number of accounts and stickers..."
    
    start_time = Time.current
    StickerCacheMonitorService.warm_all_caches
    end_time = Time.current
    
    duration = (end_time - start_time).round(2)
    puts "✅ Cache warming completed in #{duration} seconds!"
    
    # Show updated stats
    Rake::Task['sticker_cache:stats'].invoke
  end

  desc 'Perform cache health check'
  task health: :environment do
    puts "Performing sticker cache health check..."
    
    health = StickerCacheMonitorService.cache_health_check
    
    puts "\n🏥 Health Check Results:"
    puts "  Timestamp: #{health[:timestamp]}"
    puts "  Redis Available: #{health[:redis_available] ? '✅ Yes' : '❌ No'}"
    puts "  Cache Hit Rate: #{(health[:cache_hit_rate] * 100).round(1)}%"
    
    if health[:redis_available]
      if health[:cache_hit_rate] >= 0.8
        puts "  Status: ✅ Excellent - Cache is performing very well"
      elsif health[:cache_hit_rate] >= 0.6
        puts "  Status: ⚠️  Good - Cache performance is acceptable"
      elsif health[:cache_hit_rate] >= 0.4
        puts "  Status: ⚠️  Fair - Cache performance could be improved"
      else
        puts "  Status: ❌ Poor - Cache performance needs attention"
        puts "  Recommendation: Consider warming caches or checking configuration"
      end
    else
      puts "  Status: ❌ Critical - Redis is not available"
      puts "  Recommendation: Check Redis connection and configuration"
    end
    
    puts ""
  end

  desc 'Clear all sticker caches (use with caution)'
  task clear: :environment do
    puts "⚠️  WARNING: This will clear ALL sticker-related caches!"
    puts "This may temporarily impact performance until caches are rebuilt."
    print "Are you sure you want to continue? (y/N): "
    
    input = STDIN.gets.chomp.downcase
    
    if input == 'y' || input == 'yes'
      puts "Clearing sticker caches..."
      
      # Clear Giphy caches
      Rails.cache.delete_matched('giphy_stickers:*')
      
      # Clear WhatsApp media caches
      Rails.cache.delete_matched('whatsapp_media_id:*')
      
      # Clear custom stickers caches
      Rails.cache.delete_matched('custom_stickers:*')
      
      # Reset statistics
      StickerCacheMonitorService.reset_cache_stats
      
      puts "✅ All sticker caches cleared successfully!"
      puts "💡 Consider running 'rake sticker_cache:warm' to rebuild caches."
    else
      puts "Operation cancelled."
    end
  end

  desc 'Show cache configuration and recommendations'
  task config: :environment do
    puts "\n=== Sticker Cache Configuration ==="
    puts "Generated at: #{Time.current}"
    puts "=" * 50

    puts "\n📋 Current Configuration:"
    puts "  Giphy Cache TTL: #{GiphyService::CACHE_TTL / 1.minute} minutes"
    puts "  WhatsApp Media Cache TTL: #{Whatsapp::SendStickerService::MEDIA_CACHE_TTL / 1.day} days"
    puts "  Custom Stickers Cache TTL: #{StickerService::CUSTOM_STICKERS_CACHE_TTL / 1.minute} minutes"
    puts "  Sticker Packs Cache TTL: #{StickerService::STICKER_PACKS_CACHE_TTL / 1.minute} minutes"

    puts "\n🎯 Cache Key Prefixes:"
    puts "  Giphy: #{GiphyService::CACHE_PREFIX}"
    puts "  WhatsApp Media: #{Whatsapp::SendStickerService::MEDIA_CACHE_PREFIX}"
    puts "  Custom Stickers: #{StickerService::CACHE_PREFIX}"

    puts "\n💡 Recommendations:"
    puts "  • Monitor cache hit rates regularly with 'rake sticker_cache:stats'"
    puts "  • Warm caches after deployments with 'rake sticker_cache:warm'"
    puts "  • Set up monitoring alerts for hit rates below 60%"
    puts "  • Consider increasing TTL values if data doesn't change frequently"
    puts "  • Use 'rake sticker_cache:health' for automated health checks"

    puts "\n🔧 Maintenance Commands:"
    puts "  rake sticker_cache:stats     - View current statistics"
    puts "  rake sticker_cache:warm      - Pre-load caches"
    puts "  rake sticker_cache:health    - Check cache health"
    puts "  rake sticker_cache:clear     - Clear all caches (use with caution)"
    puts "  rake sticker_cache:reset_stats - Reset statistics counters"

    puts "\n" + "=" * 50
  end
end