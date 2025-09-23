class CreateOtps < ActiveRecord::Migration[7.0]
  def change
    create_table :otps do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code, null: false, limit: 6
      t.string :purpose, null: false, default: 'email_verification'
      t.boolean :verified, null: false, default: false
      t.timestamp :verified_at
      t.timestamp :expires_at, null: false
      t.string :ip_address
      t.string :user_agent
      
      t.timestamps
    end

    add_index :otps, [:user_id, :purpose, :verified]
    add_index :otps, [:code, :expires_at]
    add_index :otps, :expires_at
  end
end