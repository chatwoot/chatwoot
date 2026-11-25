class AddImportCursorToChannelEmail < ActiveRecord::Migration[7.1]
  # A column of its own rather than a key in `provider_config`, which the OAuth refresh
  # services replace wholesale on every token renewal: a Google or Microsoft inbox renews
  # long before a multi-day import finishes, so a cursor kept there is deleted mid-run and
  # the next pass starts the mailbox over. Writing it back would be worse, since the same
  # blind write can clobber credentials that were just refreshed.
  def change
    add_column :channel_email, :import_cursor, :jsonb, default: {}, null: false
  end
end
