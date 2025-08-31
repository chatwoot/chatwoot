class AddTwoFactorToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :two_factor_secret, :string
    add_column :users, :two_factor_enabled, :boolean, null: false, default: false
    add_column :users, :two_factor_backup_codes, :jsonb, default: []
    add_column :users, :two_factor_last_verified_at, :datetime
  end
end

