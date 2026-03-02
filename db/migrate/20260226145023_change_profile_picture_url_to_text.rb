class ChangeProfilePictureUrlToText < ActiveRecord::Migration[7.0]
  def up
    change_column :influencer_profiles, :profile_picture_url, :text
    change_column :influencer_profiles, :profile_url, :text
  end

  def down
    change_column :influencer_profiles, :profile_picture_url, :string
    change_column :influencer_profiles, :profile_url, :string
  end
end
