# Populate missing channel URLs on application startup
Rails.application.config.after_initialize do
  ActiveRecord::Base.connection_pool.with_connection do
    # Populate Facebook URLs
    Channel::FacebookPage.where(facebook_page_url: nil).find_each do |channel|
      next unless channel.page_id.present?

      url = "https://www.facebook.com/#{channel.page_id}"
      channel.update_column(:facebook_page_url, url)
      Rails.logger.info "Populated Facebook URL for channel #{channel.id}: #{url}"
    end

    # Populate Instagram URLs
    Channel::Instagram.where(instagram_profile_url: nil).find_each do |channel|
      inbox = channel.inbox
      next unless inbox&.name.present?

      url = "https://www.instagram.com/#{inbox.name}"
      channel.update_column(:instagram_profile_url, url)
      Rails.logger.info "Populated Instagram URL for channel #{channel.id}: #{url}"
    end
  end
rescue StandardError => e
  Rails.logger.error "Error populating channel URLs: #{e.message}"
end
