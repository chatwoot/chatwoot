class CreateSubscription < ActiveRecord::Migration[7.0]
  def change
    create_table :subscriptions do |t|
      t.references :account, null: false, foreign_key: true
      t.string :plan_name, null: false
      t.integer :max_mau, null: false, default: 0
      t.integer :max_ai_agents, null: false, default: 0
      t.integer :max_ai_responses, null: false, default: 0
      t.integer :max_human_agents, null: false, default: 0
      t.text :available_channels, array: true, default: []
      t.string :support_level
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :status, default: 'pending', null: false
      t.string :payment_status, default: 'pending', null: false
      t.string :billing_cycle, default: 'monthly', null: false
      t.string :duitku_order_id
      t.decimal :amount_paid, precision: 10, scale: 2
      t.decimal :price, precision: 10, scale: 2, null: false
      t.references :subscription_plan, null: true, index: true # Optional reference yang dapat null
      t.timestamps
    end
  end
end
