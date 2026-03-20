class CreateRecurringScheduledMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :recurring_scheduled_messages do |t|
      t.text :content
      t.jsonb :template_params, default: {}
      t.jsonb :recurrence_rule, null: false, default: {}
      t.integer :status, default: 0, null: false
      t.integer :occurrences_sent, default: 0, null: false

      t.references :account, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :inbox, null: false, foreign_key: true
      t.references :author, null: false, polymorphic: true

      t.timestamps
    end

    add_index :recurring_scheduled_messages, [:conversation_id, :status], name: 'idx_recurring_sched_msgs_on_conversation_status'
    add_index :recurring_scheduled_messages, [:account_id, :status], name: 'idx_recurring_sched_msgs_on_account_status'
    add_index :recurring_scheduled_messages, [:status], name: 'idx_recurring_sched_msgs_on_status'
  end
end
