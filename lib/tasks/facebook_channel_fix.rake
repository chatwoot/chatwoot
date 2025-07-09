namespace :facebook do
  desc "Fix Facebook channel issues and restore connectivity"
  task fix_channels: :environment do
    puts "🔧 Starting Facebook channel fix process..."
    
    facebook_channels = Channel::FacebookPage.joins(:inbox)
                                           .where(inboxes: { account: Account.active })
    
    puts "Found #{facebook_channels.count} Facebook channels to fix"
    puts ""
    
    fixed_count = 0
    failed_count = 0
    
    facebook_channels.find_each do |channel|
      puts "Fixing channel #{channel.id} (Page: #{channel.page_id})..."
      
      begin
        # Step 1: Check current token status
        refresh_service = Facebook::RefreshOauthTokenService.new(channel: channel)
        
        puts "  Current token valid: #{refresh_service.token_valid?}"
        puts "  Reauthorization required: #{channel.reauthorization_required?}"
        
        # Step 2: Clear reauthorization flag if token is valid
        if refresh_service.token_valid? && channel.reauthorization_required?
          channel.reauthorized!
          puts "  ✓ Cleared reauthorization flag"
        end
        
        # Step 3: Attempt token refresh if needed
        unless refresh_service.token_valid?
          puts "  Attempting token refresh..."
          new_token = refresh_service.attempt_token_refresh
          
          if refresh_service.token_valid?
            puts "  ✓ Token refreshed successfully"
          else
            puts "  ⚠ Token refresh failed - manual reauthorization needed"
            failed_count += 1
            next
          end
        end
        
        # Step 4: Resubscribe to webhook
        puts "  Resubscribing to webhook..."
        if channel.subscribe
          puts "  ✓ Successfully resubscribed to webhook"
          fixed_count += 1
        else
          puts "  ✗ Failed to resubscribe to webhook"
          failed_count += 1
        end
        
      rescue StandardError => e
        puts "  ✗ Error: #{e.message}"
        Rails.logger.error("Facebook channel fix error for #{channel.id}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        failed_count += 1
      end
      
      puts ""
    end
    
    puts "🏁 Facebook channel fix completed!"
    puts "✅ Fixed: #{fixed_count}"
    puts "❌ Failed: #{failed_count}"
    puts "📊 Total: #{facebook_channels.count}"
    
    if failed_count > 0
      puts ""
      puts "⚠️  Channels that failed may need manual reauthorization:"
      puts "   1. Go to Facebook App settings"
      puts "   2. Regenerate access tokens"
      puts "   3. Update channel configuration"
    end
  end
  
  desc "Check Facebook app configuration"
  task check_config: :environment do
    puts "🔍 Checking Facebook app configuration..."
    puts ""
    
    fb_app_id = GlobalConfigService.load('FB_APP_ID', '')
    fb_app_secret = GlobalConfigService.load('FB_APP_SECRET', '')
    fb_verify_token = GlobalConfigService.load('FB_VERIFY_TOKEN', '')
    
    puts "Facebook App ID: #{fb_app_id.present? ? '✓ Set' : '✗ Missing'}"
    puts "Facebook App Secret: #{fb_app_secret.present? ? '✓ Set' : '✗ Missing'}"
    puts "Facebook Verify Token: #{fb_verify_token.present? ? '✓ Set' : '✗ Missing'}"
    puts ""
    
    if fb_app_id.blank? || fb_app_secret.blank? || fb_verify_token.blank?
      puts "❌ Facebook configuration is incomplete!"
      puts "Please set the missing configuration values in the admin panel."
      return
    end
    
    puts "✅ Facebook configuration looks good!"
    
    # Test webhook URL
    webhook_url = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:3000')}/bot"
    puts "Webhook URL: #{webhook_url}"
    
    # Test provider configuration
    provider = ChatwootFbProvider.new
    puts "Provider verify token validation: #{provider.valid_verify_token?(fb_verify_token) ? '✓' : '✗'}"
    
    puts ""
    puts "🔗 Facebook App webhook configuration:"
    puts "   URL: #{webhook_url}"
    puts "   Verify Token: #{fb_verify_token}"
    puts "   Subscribe to: messages, messaging_postbacks, messaging_referrals"
  end
  
  desc "Reset all Facebook channels and force resubscribe"
  task reset_all: :environment do
    puts "🔄 Resetting all Facebook channels..."
    
    facebook_channels = Channel::FacebookPage.joins(:inbox)
                                           .where(inboxes: { account: Account.active })
    
    puts "Found #{facebook_channels.count} Facebook channels"
    puts ""
    
    success_count = 0
    failed_count = 0
    
    facebook_channels.find_each do |channel|
      begin
        puts "Resetting channel #{channel.id} (Page: #{channel.page_id})..."
        
        # Clear reauthorization flag
        if channel.reauthorization_required?
          channel.reauthorized!
          puts "  ✓ Cleared reauthorization flag"
        end
        
        # Unsubscribe first (ignore errors)
        begin
          channel.unsubscribe
          puts "  ✓ Unsubscribed from webhook"
        rescue => e
          puts "  ⚠ Unsubscribe warning: #{e.message}"
        end
        
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
    puts "🏁 Reset completed!"
    puts "✅ Success: #{success_count}"
    puts "❌ Failed: #{failed_count}"
  end
end
