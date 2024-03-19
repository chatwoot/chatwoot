class AddArchivedOnConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :closed, :boolean, default: false
  end
end
