class DropDeviseColumnsFromUsers < ActiveRecord::Migration[6.1]
  def up
    remove_column :users, :provider
    remove_column :users, :uid
    remove_column :users, :encrypted_password
    remove_column :users, :reset_password_token
    remove_column :users, :reset_password_sent_at
    remove_column :users, :remember_created_at
    remove_column :users, :confirmation_token
    remove_column :users, :confirmed_at
    remove_column :users, :confirmation_sent_at
    remove_column :users, :unconfirmed_email
    remove_column :users, :name
    remove_column :users, :nickname
    remove_column :users, :image
    remove_column :users, :email
    remove_column :users, :tokens
  end

  def down
    add_column :users, :provider, :string
    add_column :users, :uid, :string 
    add_column :users, :encrypted_password, :string 
    add_column :users, :reset_password_token, :string 
    add_column :users, :reset_password_sent_at, :datetime
    add_column :users, :remember_created_at, :datetime
    add_column :users, :confirmation_token, :string 
    add_column :users, :confirmed_at, :datetime 
    add_column :users, :confirmation_sent_at, :datetime 
    add_column :users, :unconfirmed_email, :string 
    add_column :users, :name, :string 
    add_column :users, :nickname, :string 
    add_column :users, :image, :string 
    add_column :users, :email, :string 
    add_column :users, :tokens, :json 
  end
end
