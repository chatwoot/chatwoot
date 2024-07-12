class CreateAccountPlans < ActiveRecord::Migration[7.0]
  def change
    create_table :account_plans do |t|
      t.references :account, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.timestamps
    end

    add_index :account_plans, [:account_id, :product_id], unique: true
  end
end
