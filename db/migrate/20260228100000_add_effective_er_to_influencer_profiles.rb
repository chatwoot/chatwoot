class AddEffectiveErToInfluencerProfiles < ActiveRecord::Migration[7.0]
  def change
    add_column :influencer_profiles, :effective_er, :float
  end
end
