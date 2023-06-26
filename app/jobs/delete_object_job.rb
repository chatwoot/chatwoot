class DeleteObjectJob < ApplicationJob
  queue_as :low

  def perform(object, user = nil, ip = nil)
    audited_changes = object.attributes.except('id', 'created_at', 'updated_at')
    object.destroy!
    create_audit_entry(object, user, ip, audited_changes)
  end

  def create_audit_entry(object, user, ip, audited_changes)
    return unless object.is_a?(Inbox) && user.present?

    account = object.account
    associated_type = 'Account'
    Enterprise::AuditLog.create(
      auditable_id: object.id,
      auditable_type: object.class.name,
      audited_changes: audited_changes,
      action: 'destroy',
      user_id: user.id,
      user_type: 'User',
      associated_id: account.id,
      associated_type: associated_type,
      remote_address: ip,
      comment: 'Deleted Inbox'
    )
  end
end
