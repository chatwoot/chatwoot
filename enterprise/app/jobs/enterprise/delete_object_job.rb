module Enterprise::DeleteObjectJob
  def process_post_deletion_tasks(object, user, ip)
    create_audit_entry(object, user, ip)
    cleanup_search_index(object)
  end

  def create_audit_entry(object, user, ip)
    return unless %w[Inbox Conversation].include?(object.class.to_s) && user.present?

    Enterprise::AuditLog.create(
      auditable: object,
      audited_changes: object.attributes,
      action: 'destroy',
      user: user,
      associated: object.account,
      remote_address: ip
    )
  end

  def cleanup_search_index(object)
    return unless object.is_a?(Account)
    return unless ChatwootApp.advanced_search_allowed?

    # Bulk delete all messages for this account from OpenSearch
    Message.searchkick_index.delete_by_query(
      body: {
        query: {
          term: { account_id: object.id }
        }
      }
    )
  rescue StandardError => e
    Rails.logger.error "Failed to cleanup search index for account #{object.id}: #{e.message}"
  end
end
