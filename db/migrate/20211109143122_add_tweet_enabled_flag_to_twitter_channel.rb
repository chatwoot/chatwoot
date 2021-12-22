class AddTweetEnabledFlagToTwitterChannel < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_twitter_profiles, :tweets_enabled, :boolean, default: true
  end
end
