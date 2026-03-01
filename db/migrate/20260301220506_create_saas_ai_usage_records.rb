class CreateSaasAiUsageRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :saas_ai_usage_records do |t|
      t.references :account, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :model, null: false
      t.integer :tokens_input, default: 0, null: false
      t.integer :tokens_output, default: 0, null: false
      t.integer :cost_microcents, default: 0, null: false
      t.string :feature
      t.date :recorded_on, null: false

      t.timestamps
    end

    add_index :saas_ai_usage_records, [:account_id, :recorded_on]
    add_index :saas_ai_usage_records, :recorded_on
  end
end
