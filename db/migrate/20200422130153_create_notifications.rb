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
  end
end
