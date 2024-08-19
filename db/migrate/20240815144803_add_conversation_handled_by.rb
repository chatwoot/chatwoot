class AddConversationHandledBy < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :handled_by, :integer, default: 0
  end
end
