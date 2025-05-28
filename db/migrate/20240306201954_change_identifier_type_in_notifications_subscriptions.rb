class ChangeIdentifierTypeInNotificationsSubscriptions < ActiveRecord::Migration[7.0]
  def up
    change_column :notification_subscriptions, :identifier, :text
  end

  def down
    change_column :notification_subscriptions, :identifier, :string
  end
end
