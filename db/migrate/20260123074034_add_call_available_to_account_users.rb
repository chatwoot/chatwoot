class AddCallAvailableToAccountUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :account_users, :call_available, :boolean, default: true, null: false
  end
end
