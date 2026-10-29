class AddWorkPreferencesToAccountUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :account_users, :accepts_conversations, :boolean, default: true, null: false
    add_column :account_users, :accepts_calls, :boolean, default: true, null: false
  end
end
