module Conversations::UnreadCounts::Feature
  FLAG = 'conversation_unread_counts'.freeze

  def self.enabled?(account)
    account&.feature_enabled?(FLAG)
  end
end
