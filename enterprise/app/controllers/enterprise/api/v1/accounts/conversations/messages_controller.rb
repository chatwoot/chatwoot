module Enterprise::Api::V1::Accounts::Conversations::MessagesController
  def destroy
    audited_message = message

    # Lock before the deleted check so concurrent deletes cannot both write an audit entry.
    audited_message.with_lock do
      next super if audited_message.deleted

      audit_context = message_deletion_audit_context(audited_message)
      super
      create_message_deletion_audit_log(audited_message, audit_context)
    end
  end

  private

  # Snapshot the context before super soft-deletes the message.
  def message_deletion_audit_context(deleted_message)
    {
      'content' => deleted_message.content,
      'conversation_id' => deleted_message.conversation_id,
      'display_id' => deleted_message.conversation.display_id,
      'inbox_id' => deleted_message.inbox_id,
      'sender_type' => deleted_message.sender_type,
      'sender_id' => deleted_message.sender_id
    }
  end

  def create_message_deletion_audit_log(deleted_message, audit_context)
    Enterprise::AuditLog.create!(
      auditable: deleted_message,
      action: 'destroy',
      user: Current.user,
      associated: deleted_message.account,
      remote_address: request.remote_ip,
      audited_changes: audit_context
    )
  end
end
