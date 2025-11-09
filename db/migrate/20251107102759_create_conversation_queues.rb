class CreateConversationQueues < ActiveRecord::Migration[7.1]
  def change
    create_table :conversation_queues do |t|
      t.references :conversation, null: false, foreign_key: true, index: { unique: true }
      t.references :account, null: false, foreign_key: true
      t.datetime :queued_at, null: false
      t.datetime :assigned_at
      t.datetime :left_at
      t.integer :position, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :conversation_queues, [:account_id, :status, :position]
    add_index :conversation_queues, [:account_id, :status, :queued_at]
  end
end
