class AddStatusToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :status, :integer, default: 0
    add_index :accounts, :status
  end
end
