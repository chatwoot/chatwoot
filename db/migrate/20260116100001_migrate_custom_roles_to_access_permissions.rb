# frozen_string_literal: true

# CommMate: Migrate custom role permissions to per-user access_permissions
# This migration copies permissions from custom_roles to account_users.access_permissions
# for all users that currently have a custom_role_id assigned.
# After migration, the app uses access_permissions and custom_role_id is no longer needed.
class MigrateCustomRolesToAccessPermissions < ActiveRecord::Migration[7.1]
  def up
    # Skip if custom_roles table doesn't exist (fresh install without enterprise)
    return unless table_exists?(:custom_roles)

    # Migrate permissions from custom_roles to account_users
    execute <<-SQL
      UPDATE account_users
      SET access_permissions = custom_roles.permissions
      FROM custom_roles
      WHERE account_users.custom_role_id = custom_roles.id
        AND account_users.custom_role_id IS NOT NULL
        AND (account_users.access_permissions IS NULL OR account_users.access_permissions = '{}');
    SQL

    # Null out custom_role_id after migration (permissions are now on account_users)
    execute <<-SQL
      UPDATE account_users
      SET custom_role_id = NULL
      WHERE custom_role_id IS NOT NULL;
    SQL
  end

  def down
    # NOTE: This is a one-way migration. Rolling back won't restore custom_role_id
    # because we don't know which custom_role corresponded to which permissions.
    # The access_permissions will remain on account_users.
    Rails.logger.warn 'MigrateCustomRolesToAccessPermissions: Rollback does not restore custom_role_id associations'
  end
end
