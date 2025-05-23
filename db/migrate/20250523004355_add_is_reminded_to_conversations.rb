class AddIsRemindedToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :is_reminded, :boolean, default: false, null: false
  end
end
