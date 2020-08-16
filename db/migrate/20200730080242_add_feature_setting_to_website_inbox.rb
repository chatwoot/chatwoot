class AddFeatureSettingToWebsiteInbox < ActiveRecord::Migration[6.0]
  def change
    add_column :channel_web_widgets, :feature_flags, :integer, default: 3, null: false
  end
end
