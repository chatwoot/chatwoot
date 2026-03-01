class CreateSaasPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :saas_plans do |t|
      t.string :name, null: false
      t.string :stripe_product_id
      t.string :stripe_price_id
      t.integer :price_cents, default: 0, null: false
      t.string :interval, default: 'month', null: false
      t.integer :agent_limit, default: 2
      t.integer :inbox_limit, default: 5
      t.integer :ai_tokens_monthly, default: 100_000
      t.jsonb :features, default: {}
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :saas_plans, :stripe_product_id, unique: true
    add_index :saas_plans, :stripe_price_id, unique: true
    add_index :saas_plans, :active
  end
end
