class AddSubscriptionFieldsToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_reference :accounts, :active_subscription, foreign_key: { to_table: :subscriptions }, null: true
    add_column :accounts, :subscription_status, :string, default: 'free_trial'
  end
end
