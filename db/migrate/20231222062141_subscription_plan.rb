class SubscriptionPlan < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_plans do |t|
      t.string :plan_name
      t.string :stripe_product_id, unique: true
      t.string :stripe_price_id, unique: true

      t.timestamps
    end
  end
end
