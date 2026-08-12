module Enterprise::SyncDispatcher
  def listeners
    super + [
      Captain::ConversationOutcomeEventListener.instance
    ]
  end
end
