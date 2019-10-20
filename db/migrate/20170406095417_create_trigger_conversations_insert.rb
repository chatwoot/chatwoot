class CreateTriggerConversationsInsert < ActiveRecord::Migration[5.0]
  def up
    change_column :conversations, :display_id, :integer, null: false
  end

  def down; end
end
