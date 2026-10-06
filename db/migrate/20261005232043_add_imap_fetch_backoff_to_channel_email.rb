class AddImapFetchBackoffToChannelEmail < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_email, :imap_fetch_error_count, :integer, default: 0, null: false
    add_column :channel_email, :imap_fetch_paused_till, :datetime
  end
end
