module Enterprise::Audit::TeamMember
  extend ActiveSupport::Concern

  included do
    audited on: [:create, :delete], associated_with: :account
    after_commit :create_audit_log_entry_on_create, on: :create
    after_commit :create_audit_log_entry_on_delete, on: :destroy
  end

  private

  def create_audit_log_entry_on_create
    create_audit_log_entry('add')
  end

  def create_audit_log_entry_on_delete
    create_audit_log_entry('detroy')
  end

  def create_audit_log_entry(action)
    associated_type = 'Account'
    return if team_member.nil?

    auditable_id = team_member.team_id

    account_id = Team.find_by(id: auditable_id).account_id
    auditable_type = 'Team'

    Enterprise::AuditLog.create(
      auditable_id: auditable_id,
      auditable_type: auditable_type,
      action: action,
      associated_id: account_id,
      associated_type: associated_type
    )
  end
end
