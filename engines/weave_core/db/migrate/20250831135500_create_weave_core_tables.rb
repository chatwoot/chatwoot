class CreateWeaveCoreTables < ActiveRecord::Migration[7.1]
  def change
    create_table :weave_core_account_plans do |t|
      t.references :account, null: false, foreign_key: { to_table: :accounts }
      t.string :plan_key, null: false
      t.datetime :trial_ends_at
      t.string :status, null: false, default: 'active' # active|trial|suspended
      t.timestamps
    end
    add_index :weave_core_account_plans, [:account_id], unique: true
    add_index :weave_core_account_plans, [:plan_key]

    create_table :weave_core_feature_toggles do |t|
      t.references :account, null: false, foreign_key: { to_table: :accounts }
      t.string :feature_key, null: false
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
    add_index :weave_core_feature_toggles, [:account_id, :feature_key], unique: true, name: 'idx_wsc_feature_toggle_account_feature'
  end
end

