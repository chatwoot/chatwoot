class AddUniqueDisplayId < ActiveRecord::Migration[5.0]
  def change
    remove_index(:conversations, name: 'index_conversations_on_account_id_and_display_id')
    add_index :conversations, [:account_id, :display_id], unique: true
  end
end
