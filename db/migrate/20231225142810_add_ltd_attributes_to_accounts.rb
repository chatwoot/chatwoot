class AddLtdAttributesToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :ltd_attributes, :jsonb, default: {}
  end
end
