module Enterprise::Channelable
  extend ActiveSupport::Concern

  def create_audit_log_entry
    account = self.account
    associated_type = 'Account'
    auditable_id = inbox.id
    auditable_type = 'Inbox'
    audited_changes = saved_changes.except('updated_at')

    return if audited_changes.blank?

    Enterprise::AuditLog.create(
      auditable_id: auditable_id,
      auditable_type: auditable_type,
      action: 'update',
      associated_id: account.id,
      associated_type: associated_type,
      audited_changes: audited_changes
    )
  end
end
