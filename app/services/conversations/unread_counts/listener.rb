class Conversations::UnreadCounts::Listener < BaseListener
  include Events::Types

  def message_created(event)
    message, = extract_message_and_account(event)
    return unless message.incoming?

    refresh(message.conversation)
  end

  def conversation_status_changed(event)
    conversation, = extract_conversation_and_account(event)
    refresh(conversation, event.data[:changed_attributes])
  end

  def conversation_updated(event)
    return unless label_changed?(event.data[:changed_attributes])

    conversation, = extract_conversation_and_account(event)
    refresh(conversation, event.data[:changed_attributes])
  end

  def assignee_changed(event)
    conversation, = extract_conversation_and_account(event)
    refresh(conversation, event.data[:changed_attributes])
  end

  def team_changed(event)
    conversation, = extract_conversation_and_account(event)
    refresh(conversation, event.data[:changed_attributes])
  end

  private

  def refresh(conversation, changed_attributes = nil)
    ::Conversations::UnreadCounts::Notifier.new(conversation, changed_attributes: changed_attributes).perform
  end

  def label_changed?(changed_attributes)
    return false if changed_attributes.blank?

    changed_attributes.key?('label_list') || changed_attributes.key?(:label_list) ||
      changed_attributes.key?('cached_label_list') || changed_attributes.key?(:cached_label_list)
  end
end
