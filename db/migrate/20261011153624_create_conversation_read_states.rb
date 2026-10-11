class CreateConversationReadStates < ActiveRecord::Migration[7.2]
  def change
    add_column :conversations, :read_baseline_at, :datetime
    create_table :conversation_read_states do |t|
      t.bigint :account_id, null: false
      t.bigint :conversation_id, null: false
      t.bigint :user_id, null: false
      t.datetime :last_seen_at, null: false
      t.timestamps
    end
    add_index :conversation_read_states, [:user_id, :conversation_id], unique: true
    add_index :conversation_read_states, :conversation_id
    add_index :conversation_read_states, :account_id
  end
end
