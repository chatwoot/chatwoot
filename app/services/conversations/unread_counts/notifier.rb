class Conversations::UnreadCounts::Notifier
  include Events::Types

  attr_reader :conversation, :changed_attributes

  def initialize(conversation, changed_attributes: nil)
    @conversation = conversation
    @changed_attributes = changed_attributes
  end

  def perform
    unless ::Conversations::UnreadCounts::Feature.enabled?(conversation.account)
      ::Conversations::UnreadCounts::Store.expire_ready_keys!(conversation.account_id)
      return false
    end

    return false unless ::Conversations::UnreadCounts::Refresher.new(conversation, changed_attributes: changed_attributes).perform

    Rails.configuration.dispatcher.dispatch(CONVERSATION_UNREAD_COUNT_CHANGED, Time.zone.now, conversation: conversation)
    true
  end
end
