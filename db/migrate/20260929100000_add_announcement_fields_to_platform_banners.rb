class AddAnnouncementFieldsToPlatformBanners < ActiveRecord::Migration[7.2]
  def change
    add_column :platform_banners, :title, :string
    add_column :platform_banners, :video_url, :string
  end
end
