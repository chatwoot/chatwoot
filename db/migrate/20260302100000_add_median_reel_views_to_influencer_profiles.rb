class AddMedianReelViewsToInfluencerProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :influencer_profiles, :median_reel_views, :float
  end
end
