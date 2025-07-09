namespace :facebook do
  desc "Repair deactivated Facebook channels and fix webhook subscriptions"
  task repair_channels: :environment do
    puts "🔧 Starting Facebook channel repair process..."
    
    facebook_channels = Channel::FacebookPage.joins(:inbox)
                                           .where(inboxes: { account: Account.active })
    
    puts "Found #{facebook_channels.count} Facebook channels to check"
    puts ""
    
    repaired_count = 0
    failed_count = 0
    
    facebook_channels.find_each do |channel|
      puts "Checking channel #{channel.id} (Page: #{channel.page_id})..."
      
      begin
        # 1. Kiểm tra và refresh token
        refresh_service = Facebook::RefreshOauthTokenService.new(channel: channel)
        
        if refresh_service.token_valid?
          puts "  ✓ Token is valid"
        else
          puts "  ⚠ Token invalid, attempting refresh..."
          refreshed_token = refresh_service.attempt_token_refresh
          
          if refresh_service.token_valid?
            puts "  ✓ Token refreshed successfully"
          else
            puts "  ✗ Token refresh failed - manual reauthorization required"
            failed_count += 1
            next
          end
        end
        
        # 2. Thử subscribe lại webhook
        puts "  📡 Attempting webhook subscription..."
        if channel.subscribe
          puts "  ✓ Webhook subscription successful"
          
          # 3. Clear reauthorization flag nếu có
          if channel.reauthorization_required?
            channel.reauthorized!
            puts "  ✓ Cleared reauthorization flag"
          end
          
          repaired_count += 1
          puts "  🎉 Channel #{channel.id} repaired successfully!"
        else
          puts "  ✗ Webhook subscription failed"
          failed_count += 1
        end
        
      rescue StandardError => e
        puts "  ✗ Error repairing channel #{channel.id}: #{e.message}"
        failed_count += 1
      end
      
      puts ""
    end
    
    puts "🏁 Repair process completed!"
    puts "✅ Successfully repaired: #{repaired_count} channels"
    puts "❌ Failed to repair: #{failed_count} channels"
    
    if failed_count > 0
      puts ""
      puts "💡 For failed channels, you may need to:"
      puts "   1. Check Facebook App configuration"
      puts "   2. Verify webhook URL is accessible"
      puts "   3. Manually reauthorize Facebook pages"
    end
  end
  
  desc "Test Facebook webhook configuration"
  task test_webhook: :environment do
    puts "🧪 Testing Facebook webhook configuration..."
    
    # Test basic configuration
    fb_app_id = GlobalConfigService.load('FB_APP_ID', '')
    fb_verify_token = GlobalConfigService.load('FB_VERIFY_TOKEN', '')
    fb_app_secret = GlobalConfigService.load('FB_APP_SECRET', '')
    
    puts "FB_APP_ID: #{fb_app_id.present? ? '✓ Set' : '✗ Missing'}"
    puts "FB_VERIFY_TOKEN: #{fb_verify_token.present? ? '✓ Set' : '✗ Missing'}"
    puts "FB_APP_SECRET: #{fb_app_secret.present? ? '✓ Set' : '✗ Missing'}"
    
    if fb_app_id.blank? || fb_verify_token.blank? || fb_app_secret.blank?
      puts ""
      puts "❌ Facebook configuration is incomplete!"
      puts "Please set the missing environment variables."
      return
    end
    
    puts ""
    puts "✅ Basic Facebook configuration looks good!"
    
    # Test webhook URL accessibility
    webhook_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/bot"
    puts "Webhook URL: #{webhook_url}"
    
    # Test provider configuration
    provider = ChatwootFbProvider.new
    puts "Provider verify token validation: #{provider.valid_verify_token?(fb_verify_token) ? '✓' : '✗'}"
    
    puts ""
    puts "🔗 To complete setup, configure your Facebook App webhook with:"
    puts "   URL: #{webhook_url}"
    puts "   Verify Token: #{fb_verify_token}"
    puts "   Subscribe to: messages, messaging_postbacks, messaging_referrals"
  end
  
  desc "Force resubscribe all Facebook channels"
  task force_resubscribe: :environment do
    puts "🔄 Force resubscribing all Facebook channels..."
    
    facebook_channels = Channel::FacebookPage.joins(:inbox)
                                           .where(inboxes: { account: Account.active })
    
    puts "Found #{facebook_channels.count} Facebook channels"
    puts ""
    
    success_count = 0
    failed_count = 0
    
    facebook_channels.find_each do |channel|
      begin
        puts "Resubscribing channel #{channel.id} (Page: #{channel.page_id})..."
        
        # Unsubscribe first (ignore errors)
        channel.unsubscribe
        
        # Wait a moment
        sleep(1)
        
        # Subscribe again
        if channel.subscribe
          puts "  ✓ Successfully resubscribed"
          success_count += 1
        else
          puts "  ✗ Failed to resubscribe"
          failed_count += 1
        end
        
      rescue StandardError => e
        puts "  ✗ Error: #{e.message}"
        failed_count += 1
      end
    end
    
    puts ""
    puts "🏁 Resubscription completed!"
    puts "✅ Success: #{success_count}"
    puts "❌ Failed: #{failed_count}"
  end
end
