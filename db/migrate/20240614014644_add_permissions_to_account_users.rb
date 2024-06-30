class AddPermissionsToAccountUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :account_users, :permissions, :jsonb, default: {
      # primary items
      'conversations': true,
      'reports': true,
      'contacts': true,
      # secondary items
      'accounts': true,
      'peoples': true,
      'teams': true,
      'labels': true,
      # third items
      'send_messages': true
    }
  end
end
