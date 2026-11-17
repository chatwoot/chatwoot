module Enterprise::DeleteObjectJob
  private

  def heavy_associations
    super.merge(
      SlaPolicy => %i[applied_slas]
    ).freeze
  end

  def purge_heavy_associations(object)
    unlink_conversations(object) if object.is_a?(SlaPolicy)
    super
  end

  def unlink_conversations(sla_policy)
    batch = sla_policy.conversations.limit(self.class::BATCH_SIZE)
    loop do
      break if batch.update_all(sla_policy_id: nil).zero? # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def process_post_deletion_tasks(object, user, ip)
    create_audit_entry(object, user, ip)
  end

  def create_audit_entry(object, user, ip)
    return unless %w[Inbox Conversation SlaPolicy].include?(object.class.to_s) && user.present?

    Enterprise::AuditLog.create(
      auditable: object,
      audited_changes: object.attributes,
      action: 'destroy',
      user: user,
      associated: object.account,
      remote_address: ip
    )
  end
end
