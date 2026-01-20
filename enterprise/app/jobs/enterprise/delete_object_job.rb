module Enterprise::DeleteObjectJob
  def process_post_deletion_tasks(object, user, ip, soft_deleted: false)
    create_audit_entry(object, user, ip, soft_deleted: soft_deleted)
  end

  def create_audit_entry(object, user, ip, soft_deleted: false)
    return unless %w[Inbox Conversation Contact].include?(object.class.to_s) && user.present?

    Enterprise::AuditLog.create(
      auditable: object,
      audited_changes: object.attributes,
      action: soft_deleted ? 'discard' : 'destroy',
      user: user,
      associated: object.account,
      remote_address: ip
    )
  end
end
