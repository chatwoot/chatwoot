class Conversations::UnreadCounts::Notifier
  include Events::Types

  attr_reader :conversation, :changed_attributes

  def initialize(conversation, changed_attributes: nil)
    @conversation = conversation
    @changed_attributes = changed_attributes
  end

  def perform
    return false unless conversation.account.feature_enabled?('conversation_unread_counts')

    filters_cleared = ::Conversations::UnreadCounts::Store.clear_filter_caches!(conversation.account_id)
    memberships_refreshed = ::Conversations::UnreadCounts::Refresher.new(conversation, changed_attributes: changed_attributes).perform
    return false unless memberships_refreshed || filters_cleared

    Rails.configuration.dispatcher.dispatch(CONVERSATION_UNREAD_COUNT_CHANGED, Time.zone.now, conversation: conversation)
    true
  end
end
