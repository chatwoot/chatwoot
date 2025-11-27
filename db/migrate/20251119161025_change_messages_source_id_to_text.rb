class ChangeMessagesSourceIdToText < ActiveRecord::Migration[7.1]
  def up
    change_column :messages, :source_id, :text
  end

  def down
    change_column :messages, :source_id, :string
  end
end
