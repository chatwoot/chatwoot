class AddLimitsToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :limits, :jsonb, default: {}
  end
end
