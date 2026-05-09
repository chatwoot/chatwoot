class RemoveEmployeeCodeFromAccountUsers < ActiveRecord::Migration[7.1]
  def up
    remove_index :account_users, column: [:account_id, :employee_code] if index_exists?(
      :account_users, [:account_id, :employee_code]
    )
    remove_column :account_users, :employee_code if column_exists?(:account_users, :employee_code)
  end

  def down
    add_column :account_users, :employee_code, :string unless column_exists?(:account_users, :employee_code)
    add_index :account_users, [:account_id, :employee_code], unique: true unless index_exists?(
      :account_users, [:account_id, :employee_code]
    )
  end
end
