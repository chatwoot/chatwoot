# frozen_string_literal: true

# CommMate: This migration was originally designed to update CustomRole records,
# but since we've migrated to per-user permissions, this is now a no-op.
# The campaign_manage permission is now assigned directly to users via access_permissions.
class AddCampaignManageToManagerRoles < ActiveRecord::Migration[7.1]
  def up
    # No-op: Custom roles have been replaced with per-user permissions
    # See MigrateCustomRolesToAccessPermissions migration
    Rails.logger.info 'AddCampaignManageToManagerRoles: Skipped (custom roles replaced with per-user permissions)'
  end

  def down
    # No-op
  end
end
