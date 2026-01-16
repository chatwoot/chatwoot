# frozen_string_literal: true

# CommMate: Add per-user permissions to replace enterprise Custom Roles
# This allows assigning granular permissions directly to users without
# relying on the enterprise-licensed CustomRole feature.
class AddAccessPermissionsToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :access_permissions, :text, array: true, default: []
  end
end
