class CreateScheduledMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :scheduled_messages do |t|
      t.text :content
      t.jsonb :template_params, default: {}
      t.datetime :scheduled_at
      t.integer :status, default: 0, null: false

      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true

      t.references :author, null: false, polymorphic: true
      t.references :message, null: true, foreign_key: true

      t.timestamps
    end

    add_scheduled_messages_indexes
  end

  private

  def add_scheduled_messages_indexes
    add_index :scheduled_messages, [:account_id, :status]
    add_index :scheduled_messages, [:conversation_id, :status]
    add_index :scheduled_messages, [:conversation_id, :scheduled_at]
    add_index :scheduled_messages, [:status, :scheduled_at]
    add_index :scheduled_messages, [:author_type, :author_id, :status]
    add_index :scheduled_messages, [:inbox_id, :status]
  end
end
