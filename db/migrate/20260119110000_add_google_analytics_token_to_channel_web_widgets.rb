class AddGoogleAnalyticsTokenToChannelWebWidgets < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_web_widgets, :google_analytics_token, :string
  end
end