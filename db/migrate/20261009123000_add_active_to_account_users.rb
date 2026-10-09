class AddActiveToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :active, :boolean, default: true, null: false
    add_index :account_users, [:account_id, :active]
  end
end
