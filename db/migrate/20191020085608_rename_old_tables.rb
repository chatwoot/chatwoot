class RenameOldTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :channels
    rename_table :facebook_pages, :channel_facebook_pages
    rename_table :channel_widgets, :channel_web_widgets
  end
end
