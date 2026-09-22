module Enterprise::DataImports::Importer
  private

  def update_conversation_activity(conversation)
    super
    # Bulk imports intentionally bypass Message callbacks.
    activity_at = conversation.messages.where(message_type: :incoming, private: false).maximum(:created_at)
    return unless ConversationMonitors::Scheduler.request(conversation, activity_at: activity_at)

    ConversationMonitors::Scheduler.wake(conversation.id)
  end
end
