class AddProviderNameToSocialChannels < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_instagram, :provider_name, :string
    add_column :channel_tiktok, :provider_name, :string
    add_column :channel_facebook_pages, :provider_name, :string
  end
end
