class Conversations::DeleteService
  pattr_initialize [:conversation!, :user, :ip]

  def perform
    track_deleted_email_messages
    ::DeleteObjectJob.perform_later(conversation, user, ip)
  end

  private

  def track_deleted_email_messages
    return unless conversation.inbox.email?

    Imap::DeletedMessageTracker.new(inbox: conversation.inbox).record(conversation.messages.incoming.pluck(:source_id))
  end
end
