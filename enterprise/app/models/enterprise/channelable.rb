module Enterprise::Channelable
  extend ActiveSupport::Concern

  # Active support concern has `included` which changes the order of the method lookup chain
  # https://stackoverflow.com/q/40061982/3824876
  # manually prepend the instance methods to combat this
  included do
    prepend InstanceMethods
  end

  module InstanceMethods
    def create_audit_log_entry
      account = self.account
      associated_type = 'Account'

      return if inbox.nil?

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
end
