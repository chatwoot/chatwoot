class CreateBillingProduct < ActiveRecord::Migration[7.0]
  def change
    create_table :ee_billing_products do |t|
      t.string :product_stripe_id, index: { unique: true }
      t.string :product_name
      t.string :product_description
      t.boolean :active, default: false
      t.timestamps
    end

    create_table :ee_billing_product_prices do |t|
      t.string :price_stripe_id, index: { unique: true }
      t.references :billing_product
      t.boolean :active, default: false
      t.string :stripe_nickname
      t.integer :unit_amount
      t.integer :features, default: 0, null: false
      t.jsonb :limits, default: {}, null: false

      t.timestamps
    end

    create_table :ee_account_billing_subscriptions do |t|
      t.string :subscription_stripe_id, index: { name: :subscription_stripe_id_index, unique: true }
      t.references :account, null: false, index: true
      t.references :billing_product_price, null: false, index: { name: :billing_product_price_index }
      t.string :status, null: false, default: 'true'

      t.datetime :current_period_end
      t.datetime :cancelled_at
      t.timestamps
    end
  end
end
