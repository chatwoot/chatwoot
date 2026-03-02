namespace :influencers do
  desc 'Migrate data after status enum changes: rejected→enriched, queue Apify for profiles without data'
  task migrate_statuses: :environment do
    # 1. Move rejected profiles back to enriched (if they have IC report) or discovered
    rejected = InfluencerProfile.rejected
    puts "Found #{rejected.count} rejected profiles"

    rejected.find_each do |profile|
      new_status = profile.report_fetched_at.present? ? :enriched : :discovered
      profile.update_columns(status: InfluencerProfile.statuses[new_status], rejection_reason: nil)
      puts "  #{profile.username}: rejected → #{new_status}"
    end

    # 2. Queue Apify enrichment for all profiles without apify data
    need_apify = InfluencerProfile.where(apify_enriched_at: nil)
    puts "\nFound #{need_apify.count} profiles without Apify data"

    need_apify.find_each do |profile|
      Influencers::ApifyEnrichJob.perform_later(profile.id)
      puts "  Queued Apify enrich for #{profile.username}"
    end

    puts "\nDone."
  end
end
