class CreateNotifications < ActiveRecord::Migration[6.0]
  def change
    create_table :notifications do |t|
      t.references :account, index: true, null: false
      t.references :user, index: true, null: false
      t.integer :notification_type, null: false
      t.references :primary_actor, polymorphic: true, null: false, index: { name: 'uniq_primary_actor_per_account_notifications' }
      t.references :secondary_actor, polymorphic: true, index: { name: 'uniq_secondary_actor_per_account_notifications' }
      t.timestamp :read_at, default: nil

      t.timestamps
    end

    create_table :notification_subscriptions do |t|
      t.references :user, index: true, null: false
      t.integer :subscription_type, null: false
      t.jsonb :subscription_attributes, null: false, default: '{}'
      t.timestamps
    end

    add_column :notification_settings, :push_flags, :integer, default: 0, null: false
    add_push_settings_to_users
  end

  def add_push_settings_to_users
    ::User.find_in_batches do |users_batch|
      users_batch.each do |user|
        user_notification_setting = user.notification_settings.first
        user_notification_setting.push_conversation_assignment = true
        user_notification_setting.save!
      end
    end
  end
end
