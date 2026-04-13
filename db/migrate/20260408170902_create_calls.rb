class CreateCalls < ActiveRecord::Migration[7.0]
  def change
    create_table :calls do |t|
      t.bigint :account_id, null: false
      t.bigint :inbox_id, null: false
      t.bigint :conversation_id, null: false
      t.bigint :contact_id, null: false
      t.bigint :message_id
      t.bigint :accepted_by_agent_id
      t.string :provider_call_id, null: false
      t.integer :provider, null: false, default: 0
      t.integer :direction, null: false
      t.string :status, null: false, default: 'ringing'
      t.datetime :started_at
      t.integer :duration_seconds
      t.string :end_reason
      t.jsonb :meta, default: {}
      t.text :transcript

      t.timestamps
    end

    add_call_indexes
  end

  private

  def add_call_indexes
    add_index :calls, [:provider, :provider_call_id], unique: true
    add_index :calls, [:account_id, :conversation_id]
    add_index :calls, [:account_id, :contact_id]
    add_index :calls, :message_id
  end
end
