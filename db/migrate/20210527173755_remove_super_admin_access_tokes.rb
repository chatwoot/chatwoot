class RemoveSuperAdminAccessTokes < ActiveRecord::Migration[6.0]
  def change
    AccessToken.where(owner_type: 'SuperAdmin').destroy_all
  end
end
