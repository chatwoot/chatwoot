class AddPaymentSourceAddedToSubscription < ActiveRecord::Migration[5.0]
  def change
    add_column :subscriptions, :payment_source_added, :boolean, default: false
  end
end
