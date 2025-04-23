class AddDealershipIdToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :dealership_id, :string
    add_index :accounts, :dealership_id
  end
end
