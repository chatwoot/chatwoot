class CreateAccountUsageRecords < ActiveRecord::Migration[7.1]
  def change
    create_table :account_usage_records do |t|
      t.references :account, null: false, foreign_key: true, index: false
      t.integer :ai_responses_count, default: 0, null: false
      t.integer :voice_notes_count, default: 0, null: false
      t.integer :bonus_credits, default: 0, null: false
      t.date :period_date, null: false

      t.timestamps
    end

    add_index :account_usage_records, [:account_id, :period_date],
              unique: true, name: 'idx_usage_account_period'
  end
end
