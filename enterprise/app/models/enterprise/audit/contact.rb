module Enterprise::Audit::Contact
  extend ActiveSupport::Concern

  included do
    audited associated_with: :account, on: [:destroy]

    after_discard :create_discard_audit
  end

  private

  def create_discard_audit
    create_soft_delete_audit('discard', { discarded_at: [nil, discarded_at] })
  end

  def create_soft_delete_audit(action, changes)
    Enterprise::AuditLog.create!(
      auditable_type: 'Contact',
      auditable_id: id,
      action: action,
      audited_changes: changes,
      user_id: Current.user&.id,
      user_type: Current.user ? 'User' : nil,
      associated_type: 'Account',
      associated_id: account_id,
      version: next_audit_version,
      remote_address: Audited.store[:current_remote_address],
      request_uuid: Audited.store[:current_request_uuid]
    )
  end

  def next_audit_version
    (audits.maximum(:version) || 0) + 1
  end
end
