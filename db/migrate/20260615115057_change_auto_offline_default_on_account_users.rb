class ChangeAutoOfflineDefaultOnAccountUsers < ActiveRecord::Migration[7.1]
  def up
    change_column_default :account_users, :auto_offline, false
    AccountUser.update_all(auto_offline: false) # rubocop:disable Rails/SkipsModelValidations
  end

  def down
    change_column_default :account_users, :auto_offline, true
  end
end
