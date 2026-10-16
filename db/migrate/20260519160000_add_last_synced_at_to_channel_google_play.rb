class AddLastSyncedAtToChannelGooglePlay < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_google_play, :last_synced_at, :datetime
  end
end
