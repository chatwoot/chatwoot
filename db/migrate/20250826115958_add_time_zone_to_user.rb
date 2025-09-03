class AddTimeZoneToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :timezone, :string, default: 'UTC'
  end
end
