class CreateEmployeeSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :employee_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: true, foreign_key: true
      t.string :client_id, null: false
      t.string :ip_address
      t.text :user_agent
      t.datetime :signed_in_at, null: false
      t.datetime :last_seen_at
      t.datetime :signed_out_at

      t.timestamps
    end

    add_index :employee_sessions, [:user_id, :client_id], unique: true
    add_index :employee_sessions, [:user_id, :signed_out_at]
    add_index :employee_sessions, [:account_id, :last_seen_at]
  end
end
