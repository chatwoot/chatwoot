
class CreateTriggerConversationsInsert < ActiveRecord::Migration
  def up
    change_column :conversations, :display_id, :integer, :null => false
  end

  def down
  end
end
