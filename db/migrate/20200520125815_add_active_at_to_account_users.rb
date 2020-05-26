class AddActiveAtToAccountUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :account_users, :active_at, :datetime, default: nil
  end
end
