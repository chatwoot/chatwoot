class AddLastNotifyExpiryToSubscription < ActiveRecord::Migration[7.0]
  def change
    add_column :subscriptions, :last_notify_expiry, :datetime
  end
end
