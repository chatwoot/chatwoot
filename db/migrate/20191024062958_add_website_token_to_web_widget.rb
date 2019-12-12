class AddWebsiteTokenToWebWidget < ActiveRecord::Migration[6.0]
  def change
    add_column :channel_web_widgets, :website_token, :string
    add_index :channel_web_widgets, :website_token, unique: true
  end
end
