class ConversationMonitors::Configuration
  MONTHLY_CALL_LIMIT = 100_000

  def self.enabled?(account)
    ChatwootApp.enterprise? && account.feature_enabled?('reports') && account.feature_enabled?('conversation_monitors')
  end
end
