module Enterprise::Api::V1::Accounts::Conversations::MessagesController
  def destroy
    audited_message = message
    prior_content = audited_message.content
    ActiveRecord::Base.transaction do
      super
      create_message_deletion_audit_log(audited_message, prior_content)
    end
  end

  private

  def create_message_deletion_audit_log(deleted_message, prior_content)
    Enterprise::AuditLog.create!(
      auditable: deleted_message,
      action: 'destroy',
      user: Current.user,
      associated: deleted_message.account,
      remote_address: request.remote_ip,
      audited_changes: {
        'content' => prior_content,
        'conversation_id' => deleted_message.conversation_id,
        'inbox_id' => deleted_message.inbox_id,
        'sender_type' => deleted_message.sender_type,
        'sender_id' => deleted_message.sender_id
      }
    )
  end
end
