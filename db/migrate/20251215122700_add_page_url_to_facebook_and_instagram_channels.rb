class AddPageUrlToFacebookAndInstagramChannels < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_facebook_pages, :facebook_page_url, :string
    add_column :channel_instagram, :instagram_profile_url, :string
  end
end
