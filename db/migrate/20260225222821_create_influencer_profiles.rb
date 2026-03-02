class CreateInfluencerProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :influencer_profiles do |t|
      t.references :contact, null: false, foreign_key: true, index: { unique: true }
      t.references :account, null: false, foreign_key: true

      # Identity
      t.string :platform, default: 'instagram', null: false
      t.string :username, null: false
      t.string :profile_url
      t.string :profile_picture_url
      t.string :fullname
      t.text :bio
      t.boolean :is_verified, default: false

      # Basic metrics
      t.integer :followers_count
      t.integer :following_count
      t.integer :posts_count
      t.float :engagement_rate
      t.float :avg_reel_views
      t.float :avg_likes
      t.float :avg_comments
      t.float :avg_saves
      t.float :avg_shares
      t.float :follower_growth_rate
      t.float :hidden_like_posts_rate
      t.float :paid_post_performance
      t.datetime :last_post_at

      # Audience data (from influencers.club enrich — audience_followers)
      t.float :audience_credibility
      t.string :audience_credibility_class
      t.float :audience_reachability
      t.jsonb :audience_genders, default: {}
      t.jsonb :audience_ages, default: {}
      t.jsonb :audience_geo, default: {}
      t.jsonb :audience_interests, default: {}
      t.jsonb :audience_brand_affinity, default: {}
      t.jsonb :audience_types, default: {}

      # Content data
      t.jsonb :top_hashtags, default: []
      t.jsonb :interests, default: []
      t.jsonb :recent_reels, default: []
      t.jsonb :stat_history, default: []

      # IQFluence references (renamed in later migration)
      t.string :iqfluence_report_id
      t.string :iqfluence_search_result_id
      t.jsonb :raw_report_data, default: {}

      # FQS scoring
      t.integer :fqs_score
      t.integer :fqs_stage1_score
      t.integer :fqs_stage2_score
      t.jsonb :fqs_breakdown, default: {}
      t.jsonb :fqs_hard_filter_results, default: {}

      # Workflow
      t.integer :status, default: 0
      t.string :rejection_reason
      t.string :target_market
      t.datetime :report_fetched_at
      t.datetime :last_synced_at
      t.integer :lock_version, default: 0

      t.timestamps
    end

    add_index :influencer_profiles, %i[account_id username platform], unique: true,
                                                                      name: 'idx_influencer_profiles_account_username_platform'
    add_index :influencer_profiles, %i[account_id status]
    add_index :influencer_profiles, %i[account_id fqs_score]
  end
end
