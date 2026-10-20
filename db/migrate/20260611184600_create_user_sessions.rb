class CreateUserSessions < ActiveRecord::Migration[7.0]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :client_id, null: false
      t.string :ip_address
      t.string :user_agent
      t.string :browser_name
      t.string :browser_version
      t.string :device_name
      t.string :platform_name
      t.string :platform_version
      t.string :city
      t.string :country
      t.string :country_code
      t.datetime :last_activity_at

      t.timestamps
    end

    add_index :user_sessions, [:user_id, :client_id], unique: true
  end
end
