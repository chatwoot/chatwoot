class CreateOttivAgendaTables < ActiveRecord::Migration[7.0]
  def change
    # Tabela de calendar items (lembretes, eventos, agendamentos)
    create_table :ottiv_calendar_items do |t|
      t.integer :item_type, null: false, default: 0
      t.string :title, null: false
      t.text :description
      t.datetime :start_at, null: false
      t.datetime :end_at
      t.string :location
      t.integer :status, null: false, default: 0
      t.bigint :user_id, null: false
      t.bigint :account_id, null: false
      t.bigint :conversation_id
      t.timestamps
    end

    add_index :ottiv_calendar_items, [:account_id, :user_id, :start_at], name: 'idx_ottiv_calendar_items_account_user_start'
    add_index :ottiv_calendar_items, :conversation_id, name: 'idx_ottiv_calendar_items_conversation'
    add_index :ottiv_calendar_items, [:status, :start_at], name: 'idx_ottiv_calendar_items_status_start'
    add_foreign_key :ottiv_calendar_items, :users, column: :user_id
    add_foreign_key :ottiv_calendar_items, :accounts, column: :account_id
    add_foreign_key :ottiv_calendar_items, :conversations, column: :conversation_id

    # Tabela de reminders
    create_table :ottiv_reminders do |t|
      t.bigint :ottiv_calendar_item_id, null: false
      t.datetime :notify_at, null: false
      t.integer :channel, null: false, default: 0
      t.boolean :sent, null: false, default: false
      t.timestamps
    end

    add_index :ottiv_reminders, :ottiv_calendar_item_id, name: 'idx_ottiv_reminders_calendar_item'
    add_index :ottiv_reminders, [:sent, :notify_at], name: 'idx_ottiv_reminders_sent_notify'
    add_foreign_key :ottiv_reminders, :ottiv_calendar_items, column: :ottiv_calendar_item_id

    # Tabela de scheduled messages
    create_table :ottiv_scheduled_messages do |t|
      t.string :title
      t.integer :message_type, null: false, default: 0
      t.text :content
      t.string :media_url
      t.string :audio_url
      t.bigint :quick_reply_id
      t.bigint :account_id, null: false
      t.bigint :conversation_id
      t.bigint :contact_id
      t.datetime :send_at, null: false
      t.string :timezone, default: 'UTC', null: false
      t.integer :recurrence, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.bigint :created_by, null: false
      t.datetime :sent_at
      t.timestamps
    end

    add_index :ottiv_scheduled_messages, [:status, :send_at], name: 'idx_ottiv_scheduled_messages_status_send'
    add_index :ottiv_scheduled_messages, [:account_id, :conversation_id], name: 'idx_ottiv_scheduled_messages_account_conv'
    add_index :ottiv_scheduled_messages, :created_by, name: 'idx_ottiv_scheduled_messages_creator'
    add_foreign_key :ottiv_scheduled_messages, :accounts, column: :account_id
    add_foreign_key :ottiv_scheduled_messages, :conversations, column: :conversation_id
    add_foreign_key :ottiv_scheduled_messages, :contacts, column: :contact_id
    add_foreign_key :ottiv_scheduled_messages, :users, column: :created_by

    # Tabela de occurrences (histórico de mensagens recorrentes)
    create_table :ottiv_scheduled_message_occurrences do |t|
      t.bigint :ottiv_scheduled_message_id, null: false
      t.datetime :sent_at
      t.integer :status, null: false, default: 0
      t.text :error_message
      t.timestamps
    end

    add_index :ottiv_scheduled_message_occurrences, :ottiv_scheduled_message_id, name: 'idx_ottiv_sched_msg_occ_message'
    add_foreign_key :ottiv_scheduled_message_occurrences, :ottiv_scheduled_messages, column: :ottiv_scheduled_message_id
  end
end

