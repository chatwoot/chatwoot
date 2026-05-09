class AddLocalEmployeeFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :username, :string
    add_column :users, :phone_number, :string
    add_column :users, :local_auth_enabled, :boolean, default: false, null: false
    add_column :users, :failed_login_attempts, :integer, default: 0, null: false
    add_column :users, :last_failed_login_at, :datetime
    add_column :users, :locked_at, :datetime

    add_index :users, 'lower(username)', unique: true, name: 'index_users_on_lower_username', where: 'username IS NOT NULL'
    add_index :users, :phone_number, unique: true, where: 'phone_number IS NOT NULL'
  end
end
