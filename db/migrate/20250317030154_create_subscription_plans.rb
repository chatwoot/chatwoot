class CreateSubscriptionPlans < ActiveRecord::Migration[7.0]
  def change
    create_table :subscription_plans do |t|
      t.string :name, null: false
      t.integer :max_mau, null: false, default: 0
      t.integer :max_ai_agents, null: false, default: 0
      t.integer :max_ai_responses, null: false, default: 0
      t.integer :max_human_agents, null: false, default: 0
      t.text :available_channels, array: true, default: []
      t.string :support_level
      t.integer :duration_days
      t.decimal :monthly_price, precision: 16, scale: 2, null: false
      t.decimal :annual_price, precision: 16, scale: 2, null: false
      t.boolean :is_active, default: true
      t.timestamps
    end
  end
end
