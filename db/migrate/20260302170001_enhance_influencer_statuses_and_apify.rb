class EnhanceInfluencerStatusesAndApify < ActiveRecord::Migration[7.1]
  def up
    # Apify enrichment tracking
    add_column :influencer_profiles, :apify_data, :jsonb, default: {}
    add_column :influencer_profiles, :apify_enriched_at, :datetime
    add_column :influencer_profiles, :apify_status, :integer, default: 0, null: false
    add_column :influencer_profiles, :apify_error, :string

    # Persistent recent_posts column (non-reel posts from Apify or IC)
    add_column :influencer_profiles, :recent_posts, :jsonb, default: []

    # Loading flag for async IC enrich
    add_column :influencer_profiles, :enrichment_pending, :boolean, default: false, null: false

    # Remap statuses:
    #   report_pending (1) → discovered (0)  — not yet enriched
    #   report_fetched (2) stays at 2         — now called "enriched"
    #   approved (3) stays at 3               — now called "accepted"
    #   rejected (4) unchanged
    #   contacted (5) unchanged
    # rubocop:disable Rails/SkipsModelValidations
    InfluencerProfile.where(status: 1).update_all(status: 0)

    # Data migration: rejected → enriched (if IC report exists) or discovered, clear rejection reason
    InfluencerProfile.where(status: 4).find_each do |profile|
      new_status = profile.report_fetched_at.present? ? 2 : 0
      profile.update_columns(status: new_status, rejection_reason: nil)
    end

    # Queue Apify enrichment for profiles without data
    InfluencerProfile.where(apify_enriched_at: nil).find_each do |profile|
      Influencers::ApifyEnrichJob.perform_later(profile.id)
    end
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    remove_column :influencer_profiles, :apify_data
    remove_column :influencer_profiles, :apify_enriched_at
    remove_column :influencer_profiles, :apify_status
    remove_column :influencer_profiles, :apify_error
    remove_column :influencer_profiles, :recent_posts
    remove_column :influencer_profiles, :enrichment_pending
  end
end
