class CreateSynapseosCrmEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :synapseos_crm_events do |t|
      t.references :account, null: false, foreign_key: { to_table: :accounts }
      t.references :conversation, null: true, foreign_key: { to_table: :conversations }
      t.references :user, null: true, foreign_key: { to_table: :users }

      t.string :event_type, null: false
      t.jsonb :metadata, null: false, default: {}

      t.datetime :created_at, null: false
    end

    add_index :synapseos_crm_events, [:account_id, :event_type, :created_at],
              name: 'idx_synapseos_crm_events_type_time'
    add_index :synapseos_crm_events, [:account_id, :conversation_id, :created_at],
              name: 'idx_synapseos_crm_events_conv_time'
  end
end
