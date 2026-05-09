class AddEmployeeProfileFieldsToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :job_title, :string
    add_column :account_users, :employee_notes, :text
    add_column :account_users, :active, :boolean, default: true, null: false
    add_column :account_users, :deactivation_reason, :text
    add_column :account_users, :archived_at, :datetime

    add_index :account_users, [:account_id, :active]
    add_index :account_users, [:account_id, :archived_at]
  end
end
