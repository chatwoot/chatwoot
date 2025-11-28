class CreateOttivNotificationTables < ActiveRecord::Migration[7.0]
  def change
    # Tabela de subscriptions (similar a notification_subscriptions)
    create_table :ottiv_notification_subscriptions do |t|
      t.bigint :user_id, null: false
      t.integer :subscription_type, null: false
      t.jsonb :subscription_attributes, default: {}, null: false
      t.text :identifier
      t.timestamps
    end

    add_index :ottiv_notification_subscriptions, :user_id, name: 'index_ottiv_notification_subscriptions_on_user_id'
    add_index :ottiv_notification_subscriptions, :identifier, unique: true, name: 'index_ottiv_notification_subscriptions_on_identifier'
    add_foreign_key :ottiv_notification_subscriptions, :users, column: :user_id

    # Tabela de settings (similar a notification_settings)
    create_table :ottiv_notification_settings do |t|
      t.integer :account_id
      t.integer :user_id
      t.integer :email_flags, default: 0, null: false
      t.integer :push_flags, default: 0, null: false
      t.timestamps
    end

    add_index :ottiv_notification_settings, [:account_id, :user_id], unique: true, name: 'by_account_user_ottiv'
    add_foreign_key :ottiv_notification_settings, :accounts, column: :account_id
    add_foreign_key :ottiv_notification_settings, :users, column: :user_id

    # Tabela de notifications (similar a notifications)
    create_table :ottiv_notifications do |t|
      t.bigint :account_id, null: false
      t.bigint :user_id, null: false
      t.integer :notification_type, null: false
      t.string :primary_actor_type, null: false
      t.bigint :primary_actor_id, null: false
      t.string :secondary_actor_type
      t.bigint :secondary_actor_id
      t.datetime :read_at, precision: nil
      t.datetime :snoozed_until
      t.datetime :last_activity_at, default: -> { 'CURRENT_TIMESTAMP' }
      t.jsonb :meta, default: {}
      t.timestamps
    end

    add_index :ottiv_notifications, :account_id, name: 'index_ottiv_notifications_on_account_id'
    add_index :ottiv_notifications, :user_id, name: 'index_ottiv_notifications_on_user_id'
    add_index :ottiv_notifications, :last_activity_at, name: 'index_ottiv_notifications_on_last_activity_at'
    add_index :ottiv_notifications, [:primary_actor_type, :primary_actor_id],
              name: 'uniq_primary_actor_per_account_ottiv_notifications'
    add_index :ottiv_notifications, [:secondary_actor_type, :secondary_actor_id],
              name: 'uniq_secondary_actor_per_account_ottiv_notifications'
    add_index :ottiv_notifications, [:user_id, :account_id, :snoozed_until, :read_at],
              name: 'idx_ottiv_notifications_performance'
    add_foreign_key :ottiv_notifications, :accounts, column: :account_id
    add_foreign_key :ottiv_notifications, :users, column: :user_id
  end
end
