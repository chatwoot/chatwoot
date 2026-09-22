class ConversationMonitors::Configuration
  def self.enabled?(account)
    ChatwootApp.enterprise? && account.feature_enabled?('reports') && account.feature_enabled?('conversation_monitors')
  end
end
