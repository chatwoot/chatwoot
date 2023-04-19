class AddPriorityToConversation < ActiveRecord::Migration[6.1]
  def change
    add_column :conversations, :priority, :integer
    add_index :conversations, :priority
    add_index :conversations, [:status, :priority]
  end
end
