# Facebook Token Refresh Rake Tasks
# These tasks help manage Facebook token refresh operations

namespace :facebook do
  namespace :tokens do
    desc "Refresh all Facebook tokens"
    task refresh_all: :environment do
      puts "Starting Facebook token refresh for all channels..."
      
      facebook_channels = Channel::FacebookPage.joins(:inbox)
                                             .where(inboxes: { account: Account.active })
      
      puts "Found #{facebook_channels.count} Facebook channels to check"
      
      success_count = 0
      error_count = 0
      
      facebook_channels.find_each do |channel|
        begin
          refresh_service = Facebook::RefreshOauthTokenService.new(channel: channel)
          
          puts "Checking channel #{channel.id} (Page: #{channel.page_id})..."
          
          if refresh_service.token_valid?
            puts "  ✓ Token is valid"
            success_count += 1
          else
            puts "  ⚠ Token invalid, attempting refresh..."
            result = refresh_service.attempt_token_refresh
            
            if refresh_service.token_valid?
              puts "  ✓ Token successfully refreshed"
              success_count += 1
            else
              puts "  ✗ Token refresh failed - manual reauthorization required"
              error_count += 1
            end
          end
        rescue StandardError => e
          puts "  ✗ Error: #{e.message}"
          error_count += 1
        end
      end
      
      puts "\nSummary:"
      puts "  Successful: #{success_count}"
      puts "  Errors: #{error_count}"
      puts "  Total: #{facebook_channels.count}"
    end

    desc "Check Facebook token status for all channels"
    task check_all: :environment do
      puts "Checking Facebook token status for all channels..."
      
      facebook_channels = Channel::FacebookPage.joins(:inbox)
                                             .where(inboxes: { account: Account.active })
      
      puts "Found #{facebook_channels.count} Facebook channels"
      puts ""
      
      facebook_channels.find_each do |channel|
        begin
          refresh_service = Facebook::RefreshOauthTokenService.new(channel: channel)
          
          status = if refresh_service.token_valid?
                    "✓ Valid"
                  else
                    "✗ Invalid"
                  end
          
          reauth_status = if channel.reauthorization_required?
                           " (Reauth Required)"
                         else
                           ""
                         end
          
          puts "Channel #{channel.id} (Page: #{channel.page_id}): #{status}#{reauth_status}"
        rescue StandardError => e
          puts "Channel #{channel.id} (Page: #{channel.page_id}): Error - #{e.message}"
        end
      end
    end

    desc "Refresh token for specific channel"
    task :refresh_channel, [:channel_id] => :environment do |t, args|
      channel_id = args[:channel_id]
      
      if channel_id.blank?
        puts "Usage: rake facebook:tokens:refresh_channel[CHANNEL_ID]"
        exit 1
      end
      
      begin
        channel = Channel::FacebookPage.find(channel_id)
        refresh_service = Facebook::RefreshOauthTokenService.new(channel: channel)
        
        puts "Refreshing token for channel #{channel_id} (Page: #{channel.page_id})..."
        
        if refresh_service.token_valid?
          puts "Token is already valid"
        else
          puts "Token invalid, attempting refresh..."
          result = refresh_service.attempt_token_refresh
          
          if refresh_service.token_valid?
            puts "✓ Token successfully refreshed"
          else
            puts "✗ Token refresh failed - manual reauthorization required"
          end
        end
      rescue ActiveRecord::RecordNotFound
        puts "Channel with ID #{channel_id} not found"
        exit 1
      rescue StandardError => e
        puts "Error: #{e.message}"
        exit 1
      end
    end

    desc "Clear reauthorization flags for channels with valid tokens"
    task clear_reauth_flags: :environment do
      puts "Clearing reauthorization flags for channels with valid tokens..."
      
      facebook_channels = Channel::FacebookPage.joins(:inbox)
                                             .where(inboxes: { account: Account.active })
      
      cleared_count = 0
      
      facebook_channels.find_each do |channel|
        next unless channel.reauthorization_required?
        
        begin
          refresh_service = Facebook::RefreshOauthTokenService.new(channel: channel)
          
          if refresh_service.token_valid?
            channel.reauthorized!
            puts "✓ Cleared reauth flag for channel #{channel.id} (Page: #{channel.page_id})"
            cleared_count += 1
          end
        rescue StandardError => e
          puts "✗ Error checking channel #{channel.id}: #{e.message}"
        end
      end
      
      puts "\nCleared reauthorization flags for #{cleared_count} channels"
    end

    desc "Run Facebook token refresh job"
    task run_job: :environment do
      puts "Running FacebookTokenRefreshJob..."
      FacebookTokenRefreshJob.perform_now
      puts "Job completed"
    end
  end
end
