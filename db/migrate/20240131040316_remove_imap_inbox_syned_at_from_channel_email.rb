class RemoveImapInboxSynedAtFromChannelEmail < ActiveRecord::Migration[7.0]
  def change
    remove_column :channel_email, :imap_inbox_synced_at, :datetime
  end
end
