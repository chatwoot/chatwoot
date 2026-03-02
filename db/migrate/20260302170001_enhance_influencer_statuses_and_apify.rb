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
    InfluencerProfile.where(status: 1).update_all(status: 0) # rubocop:disable Rails/SkipsModelValidations
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
