module Enterprise::Captain::JevClient
  def call(body:, &)
    ConversationMonitors::Usage.new(@account_id).reserve!
    super
  end
end
