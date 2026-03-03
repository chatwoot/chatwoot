class AddTrialAndOverageFields < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :trial_credits_remaining, :integer, default: 0, null: false
    add_column :account_usage_records, :overage_count, :integer, default: 0, null: false
  end
end
