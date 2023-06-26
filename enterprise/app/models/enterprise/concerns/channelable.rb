module Enteprise::Channelable
  extend ActiveSupport::Concern

  def create_audit_log_entry
    account = self.account
    associated_type = 'Account'
    auditable_id = inbox_id
    auditable_type = 'Inbox'
    audited_changes = attributes.except('id', 'created_at', 'updated_at')

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
