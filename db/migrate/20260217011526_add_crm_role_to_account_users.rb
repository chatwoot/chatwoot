class AddCrmRoleToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :crm_role, :string
  end
end
