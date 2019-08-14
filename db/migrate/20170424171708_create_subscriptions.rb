class CreateSubscriptions < ActiveRecord::Migration[5.0]
  def change
    create_table :subscriptions do |t|
      t.string :pricing_version
      t.integer :account_id
      t.datetime :expiry
      t.string :billing_plan, default: 'trial'
      t.string :stripe_customer_id
      t.timestamps
    end
  end
end
