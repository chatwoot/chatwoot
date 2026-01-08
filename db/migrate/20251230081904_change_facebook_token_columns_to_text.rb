class ChangeFacebookTokenColumnsToText < ActiveRecord::Migration[7.1]
  def change
    change_column :channel_facebook_pages, :user_access_token, :text
    change_column :channel_facebook_pages, :page_access_token, :text
  end
end
