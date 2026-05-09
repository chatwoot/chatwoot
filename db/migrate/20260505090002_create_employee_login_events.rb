class CreateEmployeeLoginEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :employee_login_events do |t|
      t.references :user, null: true, foreign_key: true
      t.references :account, null: true, foreign_key: true
      t.boolean :success, default: false, null: false
      t.string :login_identifier
      t.string :ip_address
      t.text :user_agent
      t.string :failure_reason

      t.timestamps
    end

    add_index :employee_login_events, [:user_id, :created_at]
    add_index :employee_login_events, [:account_id, :created_at]
    add_index :employee_login_events, [:success, :created_at]
  end
end
