class AddEmailDigestEnabledToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :email_digest_enabled, :boolean, default: true
  end
end
