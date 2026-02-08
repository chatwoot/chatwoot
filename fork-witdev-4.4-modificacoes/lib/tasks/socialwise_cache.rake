# frozen_string_literal: true

namespace :socialwise do
  namespace :cache do
    desc 'Show SocialWise cache statistics'
    task stats: :environment do
      puts "\n=== SocialWise Cache Statistics ==="
      
      stats = Integrations::Socialwise::CacheManager.cache_stats
      
      if stats.empty?
        puts "No cache statistics available."
      else
        stats.each do |cache_type, data|
          puts "\n#{cache_type.upcase}:"
          puts "  Hits: #{data[:hits]}"
          puts "  Misses: #{data[:misses]}"
          puts "  Total: #{data[:total]}"
          puts "  Hit Rate: #{data[:hit_rate]}%"
        end
      end
      
      puts "\n=== Cache Health Check ==="
      health = Integrations::Socialwise::CacheManager.health_check
      puts "Status: #{health[:status]}"
      puts "Timestamp: #{health[:timestamp]}"
      puts "Error: #{health[:error]}" if health[:error]
      
      puts "\n"
    end
    
    desc 'Clear all SocialWise cache'
    task clear: :environment do
      puts "Clearing all SocialWise cache..."
      
      deleted_count = Integrations::Socialwise::CacheManager.clear_all_cache
      
      puts "Cleared #{deleted_count} cache entries."
    end
    
    desc 'Clear cache for a specific inbox'
    task :clear_inbox, [:inbox_id] => :environment do |t, args|
      inbox_id = args[:inbox_id]
      
      if inbox_id.blank?
        puts "Usage: rake socialwise:cache:clear_inbox[INBOX_ID]"
        exit 1
      end
      
      puts "Clearing cache for inbox #{inbox_id}..."
      
      deleted_count = Integrations::Socialwise::CacheManager.clear_inbox_cache(inbox_id)
      
      puts "Cleared #{deleted_count} cache entries for inbox #{inbox_id}."
    end
    
    desc 'Preload cache for WhatsApp inboxes'
    task preload: :environment do
      puts "Preloading cache for all WhatsApp inboxes..."
      
      preloaded_count = Integrations::Socialwise::CacheManager.preload_whatsapp_cache
      
      puts "Preloaded cache for #{preloaded_count} WhatsApp inboxes."
    end
    
    desc 'Preload cache for WhatsApp inboxes of a specific account'
    task :preload_account, [:account_id] => :environment do |t, args|
      account_id = args[:account_id]
      
      if account_id.blank?
        puts "Usage: rake socialwise:cache:preload_account[ACCOUNT_ID]"
        exit 1
      end
      
      puts "Preloading cache for WhatsApp inboxes of account #{account_id}..."
      
      preloaded_count = Integrations::Socialwise::CacheManager.preload_whatsapp_cache(account_id.to_i)
      
      puts "Preloaded cache for #{preloaded_count} WhatsApp inboxes."
    end
    
    desc 'Test cache functionality'
    task test: :environment do
      puts "\n=== Testing SocialWise Cache Functionality ==="
      
      # Health check
      puts "\n1. Health Check:"
      health = Integrations::Socialwise::CacheManager.health_check
      puts "   Status: #{health[:status]}"
      
      if health[:status] == 'healthy'
        puts "   ✅ Cache system is working properly"
      else
        puts "   ❌ Cache system has issues: #{health[:error]}"
        exit 1
      end
      
      # Find a test inbox
      test_inbox = Inbox.joins(:channel).where(channels: { type: 'Channel::Whatsapp' }).first
      
      if test_inbox
        puts "\n2. Testing with inbox #{test_inbox.id}:"
        
        # Clear cache first
        Integrations::Socialwise::CacheManager.clear_inbox_cache(test_inbox.id)
        puts "   Cleared existing cache"
        
        # Test cache miss
        puts "   Testing cache miss..."
        channel_type = Integrations::Socialwise::CacheManager.channel_type(test_inbox.id) do
          puts "   📥 Cache miss - fetching from database"
          test_inbox.channel_type
        end
        puts "   Channel type: #{channel_type}"
        
        # Test cache hit
        puts "   Testing cache hit..."
        cached_channel_type = Integrations::Socialwise::CacheManager.channel_type(test_inbox.id) do
          puts "   ❌ This should not be called (cache hit expected)"
          test_inbox.channel_type
        end
        puts "   Cached channel type: #{cached_channel_type}"
        
        if channel_type == cached_channel_type
          puts "   ✅ Cache hit/miss working correctly"
        else
          puts "   ❌ Cache hit/miss not working properly"
        end
        
        # Clean up
        Integrations::Socialwise::CacheManager.clear_inbox_cache(test_inbox.id)
        puts "   Cleaned up test cache"
      else
        puts "\n2. No WhatsApp inbox found for testing"
      end
      
      # Show final stats
      puts "\n3. Final Statistics:"
      stats = Integrations::Socialwise::CacheManager.cache_stats
      stats.each do |cache_type, data|
        puts "   #{cache_type}: #{data[:hits]} hits, #{data[:misses]} misses (#{data[:hit_rate]}% hit rate)"
      end
      
      puts "\n✅ Cache test completed successfully!"
    end
    
    desc 'Monitor cache performance in real-time'
    task monitor: :environment do
      puts "Monitoring SocialWise cache performance (Press Ctrl+C to stop)..."
      puts "Time\t\tChannel Type\t\tProvider Config\t\tInbox Data"
      puts "=" * 80
      
      trap("INT") { puts "\nMonitoring stopped."; exit }
      
      loop do
        stats = Integrations::Socialwise::CacheManager.cache_stats
        
        channel_stats = stats['channel_type'] || { hit_rate: 0, total: 0 }
        provider_stats = stats['provider_config'] || { hit_rate: 0, total: 0 }
        inbox_stats = stats['inbox_data'] || { hit_rate: 0, total: 0 }
        
        timestamp = Time.current.strftime("%H:%M:%S")
        
        printf "%s\t%.1f%% (%d)\t\t%.1f%% (%d)\t\t%.1f%% (%d)\n",
               timestamp,
               channel_stats[:hit_rate], channel_stats[:total],
               provider_stats[:hit_rate], provider_stats[:total],
               inbox_stats[:hit_rate], inbox_stats[:total]
        
        sleep 5
      end
    end
  end
end