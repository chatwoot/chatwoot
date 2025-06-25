class RemoveSubscriptions < ActiveRecord::Migration[6.0]
  def change
    drop_table :subscriptions do |t|
      t.string 'pricing_version'
      t.integer 'account_id'
      t.datetime 'expiry'
      t.string 'billing_plan', default: 'trial'
      t.string 'stripe_customer_id'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.integer 'state', default: 0
      t.boolean 'payment_source_added', default: false
    end
  end
end
