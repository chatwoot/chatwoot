class AddPermissionsToAccountUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :account_users, :permissions, :jsonb, default: {
      'conversations': true,
      'accounts': true,
      'teams': true,
      'reports': true,
      'contacts': true,
      'labels': true
    }
  end
end
