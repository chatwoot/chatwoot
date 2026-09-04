namespace :instagram do
  desc 'Re-subscribe existing Instagram Login channels so the comments webhook field is enabled'
  task resubscribe_comments: :environment do
    resubscribed = 0
    needs_reauth = 0

    Channel::Instagram.find_each do |channel|
      response = channel.subscribe

      if response.respond_to?(:success?) && response.success?
        resubscribed += 1
        Rails.logger.info("Re-subscribed Instagram channel ##{channel.id} (#{channel.instagram_id})")
      else
        # Channels connected before comments support was added may hold a token minted
        # without `instagram_business_manage_comments`; flag them for reauthorization
        # instead of reporting a false success.
        channel.prompt_reauthorization!
        needs_reauth += 1
        Rails.logger.warn("Instagram channel ##{channel.id} (#{channel.instagram_id}) needs reauthorization to receive comments")
      end
    end

    Rails.logger.info("Done. Re-subscribed #{resubscribed} Instagram channel(s); #{needs_reauth} need reauthorization.")
  end
end
