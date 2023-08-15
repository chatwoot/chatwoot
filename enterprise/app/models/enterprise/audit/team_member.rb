module Enterprise::Audit::TeamMember
  extend ActiveSupport::Concern

  included do
    audited on: [:create, :delete]
    after_commit :create_audit_log_entry_on_create, on: :create
    after_commit :create_audit_log_entry_on_delete, on: :destroy
  end

  private

  def create_audit_log_entry_on_create
    create_audit_log_entry('create')
  end

  def create_audit_log_entry_on_delete
    create_audit_log_entry('destroy')
  end

  def create_audit_log_entry(action)
    return if nil?

    auditable_id = team_id

    account_id = Team.find_by(id: auditable_id).account_id
    auditable_type = 'TeamMember'

    audited_changes = attributes.except('updated_at', 'created_at')

    Enterprise::AuditLog.create(
      auditable_id: auditable_id,
      auditable_type: auditable_type,
      action: action,
      associated_id: account_id,
      audited_changes: audited_changes,
      associated_type: 'Account'
    )
  end

  def find_account_id(auditable_id)
    Team.find_by(id: auditable_id)&.account_id
  end
end
