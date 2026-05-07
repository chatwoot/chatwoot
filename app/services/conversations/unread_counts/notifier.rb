class Conversations::UnreadCounts::Notifier
  include Events::Types

  attr_reader :conversation, :changed_attributes

  def initialize(conversation, changed_attributes: nil)
    @conversation = conversation
    @changed_attributes = changed_attributes
  end

  def perform
    return false unless ::Conversations::UnreadCounts::Feature.enabled?(conversation.account)
    return false unless ::Conversations::UnreadCounts::Refresher.new(conversation, changed_attributes: changed_attributes).perform

    Rails.configuration.dispatcher.dispatch(CONVERSATION_UNREAD_COUNT_CHANGED, Time.zone.now, conversation: conversation)
    true
  end
end
