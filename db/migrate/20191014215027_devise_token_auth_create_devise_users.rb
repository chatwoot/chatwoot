class DeviseTokenAuthCreateDeviseUsers < ActiveRecord::Migration[6.1]
  def change
    create_table(:devise_users) do |t|
      ## Required
      t.string :provider, :null => false, :default => "email"
      t.string :uid, :null => false, :default => ""

      ## Database authenticatable
      t.string :encrypted_password, :null => false, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## User Info
      t.string :name
      t.string :nickname
      t.string :image
      t.string :email

      ## Tokens
      t.json :tokens

      t.timestamps

      # others
      t.integer :sign_in_count, null: false, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
    end

    add_index :devise_users, :email,                unique: true
    add_index :devise_users, [:uid, :provider],     unique: true
    add_index :devise_users, :reset_password_token, unique: true
    # add_index :devise_users, :confirmation_token,   unique: true
    # add_index :devise_users, :unlock_token,       unique: true
  end
end
