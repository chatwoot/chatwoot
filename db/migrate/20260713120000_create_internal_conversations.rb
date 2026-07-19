class CreateInternalConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :internal_conversations do |t|
      t.references :account, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.datetime :last_activity_at
      t.string :last_message_preview, limit: 140
      t.timestamps
    end

    add_index :internal_conversations, [:account_id, :team_id], unique: true

    create_table :internal_messages do |t|
      t.references :account, null: false, foreign_key: true
      t.references :internal_conversation, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.timestamps
    end

    add_index :internal_messages, [:internal_conversation_id, :id]
    add_index :internal_messages, [:account_id, :created_at]
  end
end
