class AddConversationType < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :conversation_type, :integer, default: 0, null: false
  end
end
