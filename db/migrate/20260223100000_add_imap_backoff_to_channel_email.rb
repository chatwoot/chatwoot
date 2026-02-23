class AddImapBackoffToChannelEmail < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_email, :imap_retry_count, :integer, default: 0, null: false
    add_column :channel_email, :imap_retry_after, :datetime
  end
end
