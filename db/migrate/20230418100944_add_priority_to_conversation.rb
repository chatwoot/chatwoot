class AddPriorityToConversation < ActiveRecord::Migration[6.1]
  def change
    add_column :conversations, :priority, :integer
  end
end
