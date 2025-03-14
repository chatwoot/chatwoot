class CreatePricingPlans < ActiveRecord::Migration[6.1]
  def change
    create_table :pricing_plans do |t|
      t.string :name
      t.integer :price
      t.text :description
      t.integer :max_active_users
      t.integer :human_agents
      t.integer :ai_responses
      t.boolean :dedicated_support, default: false
      t.boolean :openapi_access, default: false
      t.string :tag, default: "regular" # Bisa 'popular', 'premium', etc.

      t.timestamps
    end
  end
end
