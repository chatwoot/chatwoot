class AddSearchEngagementRateToInfluencerProfiles < ActiveRecord::Migration[7.1]
  def change
    add_column :influencer_profiles, :search_engagement_rate, :float
  end
end
