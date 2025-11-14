class IncreaseContactInboxSourceIdLength < ActiveRecord::Migration[7.1]
  def up
    change_column :contact_inboxes, :source_id, :string, limit: 1024
  end

  def down
    change_column :contact_inboxes, :source_id, :string, limit: 255
  end
end
