class AddInternalAttributesToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :internal_attributes, :jsonb, null: false, default: {}
  end
end
