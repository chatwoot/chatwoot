class CreateConversationAssignmentEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :conversation_assignment_events do |t|
      t.references :account, null: false
      t.references :conversation, null: false
      t.bigint :inbox_id, null: false
      t.bigint :agent_id, null: false
      t.bigint :conversation_display_id, null: false
      t.string :agent_name, null: false
      t.string :event_kind, null: false
      t.string :source, null: false
      t.jsonb :routing, null: false, default: {}
      t.datetime :first_customer_message_at
      t.datetime :assigned_at, null: false
      t.datetime :synced_at
      t.timestamps
    end
    add_index :conversation_assignment_events, :id, where: 'synced_at IS NULL', name: 'assignment_events_pending'
  end
end
