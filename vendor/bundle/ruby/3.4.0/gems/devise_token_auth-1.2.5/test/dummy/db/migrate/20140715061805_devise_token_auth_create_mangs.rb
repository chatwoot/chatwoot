# frozen_string_literal: true

include MigrationDatabaseHelper

class DeviseTokenAuthCreateMangs < ActiveRecord::Migration[4.2]
  def change
    create_table(:mangs) do |t|
      ## Database authenticatable
      t.string :email
      t.string :encrypted_password, null: false, default: ''

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.string   :reset_password_redirect_url
      t.boolean  :allow_password_change, default: false

      ## Rememberable
      t.datetime :remember_created_at

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, :default => 0, :null => false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      ## User Info
      t.string :name
      t.string :nickname
      t.string :image

      ## unique oauth id
      t.string :provider
      t.string :uid, null: false, default: ''

      ## Tokens
      if json_supported_database?
        t.json :tokens
      else
        t.text :tokens
      end

      t.timestamps
    end

    add_index :mangs, :email
    add_index :mangs, [:uid, :provider],     unique: true
    add_index :mangs, :reset_password_token, unique: true
    add_index :mangs, :confirmation_token,   unique: true
    # add_index :mangs, :unlock_token,         :unique => true
  end
end
