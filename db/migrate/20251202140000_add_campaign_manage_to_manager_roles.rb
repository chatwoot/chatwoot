# frozen_string_literal: true

class AddCampaignManageToManagerRoles < ActiveRecord::Migration[7.1]
  def up
    return unless ActiveRecord::Base.connection.table_exists?('custom_roles')

    # Add campaign_manage permission to existing Manager roles
    CustomRole.where(name: 'Manager').find_each do |role|
      next if role.permissions.include?('campaign_manage')

      role.permissions << 'campaign_manage'
      role.save!
    end
  end

  def down
    # Remove campaign_manage permission from Manager roles
    CustomRole.where(name: 'Manager').find_each do |role|
      role.permissions.delete('campaign_manage')
      role.save!
    end
  end
end

