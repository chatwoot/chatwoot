class SuperAdminAuditLog < ApplicationRecord
  # Preserve historical IDs even after either user is deleted.
  belongs_to :super_admin, optional: true
  belongs_to :target_user, class_name: 'User', optional: true

  validates :super_admin_id, :action, presence: true
end
