class Conversations::UnreadCounts::Notifier
  include Events::Types

  attr_reader :conversation, :changed_attributes

  def initialize(conversation, changed_attributes: nil)
    @conversation = conversation
    @changed_attributes = changed_attributes
  end

  def perform
    return false unless conversation.account.feature_enabled?('conversation_unread_counts')
    return dispatch_unread_count_changed if ::Conversations::UnreadCounts::Refresher.new(conversation, changed_attributes: changed_attributes).perform
    return false unless conversation.account.feature_enabled?(filtered_count_feature_flag)

    dispatch_unread_count_changed
  end

  private

  def dispatch_unread_count_changed
    Rails.configuration.dispatcher.dispatch(CONVERSATION_UNREAD_COUNT_CHANGED, Time.zone.now, conversation: conversation)
    true
  end

  def filtered_count_feature_flag
    ::Conversations::UnreadCounts::FilteredCountInvalidator::FEATURE_FLAG
  end
end
