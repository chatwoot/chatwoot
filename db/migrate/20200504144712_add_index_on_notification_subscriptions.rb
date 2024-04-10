class AddIndexOnNotificationSubscriptions < ActiveRecord::Migration[6.0]
  def change
    add_column :notification_subscriptions, :identifier, :string
    add_index :notification_subscriptions, :identifier, unique: true
  end
end
