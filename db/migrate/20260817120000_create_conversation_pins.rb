class CreateConversationPins < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_pins do |t|
      t.bigint :account_id, null: false
      t.bigint :user_id, null: false
      t.bigint :conversation_id, null: false

      t.timestamps
    end

    add_index :conversation_pins, :account_id
    add_index :conversation_pins, :conversation_id
    add_index :conversation_pins, [:user_id, :conversation_id], unique: true
  end
end
