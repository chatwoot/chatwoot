class AddConversationUuidUniqueIndex < ActiveRecord::Migration[6.1]
  def change
    add_index :conversations, :uuid, unique: true
  end
end
