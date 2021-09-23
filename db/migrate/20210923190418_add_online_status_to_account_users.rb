class AddOnlineStatusToAccountUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :account_users, :availability, :integer, default: 0
    add_column :account_users, :auto_offline, :boolean, default: true

    #TODO add migration for existing online statuses
  end
end
