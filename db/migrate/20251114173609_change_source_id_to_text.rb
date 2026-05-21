class ChangeSourceIdToText < ActiveRecord::Migration[7.1]
  def up
    change_column :contact_inboxes, :source_id, :text, null: false
  end

  def down
    change_column :contact_inboxes, :source_id, :string, null: false
  end
end
