class CreateAccountPlans < ActiveRecord::Migration[7.0]
  def change
    create_table :account_plans do |t|
      t.references :account, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :extra_conversations, null: false, default: 0
      t.integer :extra_agents, null: false, default: 0
      t.timestamps
    end

    add_index :account_plans, [:account_id, :product_id], unique: true
  end

  def down
    drop_table :account_plans
  end
end
