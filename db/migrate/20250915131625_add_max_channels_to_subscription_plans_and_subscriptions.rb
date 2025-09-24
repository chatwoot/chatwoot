class AddMaxChannelsToSubscriptionPlansAndSubscriptions < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_plans, :max_channels, :integer, default: 0
    add_column :subscriptions, :max_channels, :integer, default: 0
  end
end
