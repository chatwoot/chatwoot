class Conversations::UnreadCounts::Listener < BaseListener
  include Events::Types

  def message_created(event)
    message, = extract_message_and_account(event)
    return unless message.incoming?
    return unless message.account.feature_enabled?('conversation_unread_counts')

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

  def conversation_deleted(event)
    conversation_data = event.data[:conversation_data]&.with_indifferent_access
    return if conversation_data.blank?

    account = Account.find_by(id: conversation_data[:account_id])
    return unless account&.feature_enabled?('conversation_unread_counts')
    return unless remove_deleted_conversation(account, conversation_data)

    Rails.configuration.dispatcher.dispatch(CONVERSATION_UNREAD_COUNT_CHANGED, Time.zone.now, conversation_data: conversation_data.to_h)
  end

  private

  def refresh(conversation, changed_attributes = nil)
    ::Conversations::UnreadCounts::Notifier.new(conversation, changed_attributes: changed_attributes).perform
  end

  def remove_deleted_conversation(account, conversation_data)
    return false unless store.base_ready?(account.id) || store.assignment_ready?(account.id)

    removed = false
    removed = remove_deleted_base_membership(account, conversation_data) || removed if store.base_ready?(account.id)
    removed = remove_deleted_assignment_membership(account, conversation_data) || removed if store.assignment_ready?(account.id)
    removed
  end

  def remove_deleted_base_membership(account, conversation_data)
    store.remove_base_membership(
      account_id: account.id,
      inbox_ids: [conversation_data[:inbox_id]],
      label_ids: label_ids_for(account, conversation_data[:cached_label_list]),
      team_ids: [conversation_data[:team_id]],
      conversation_id: conversation_data[:id]
    )
  end

  def remove_deleted_assignment_membership(account, conversation_data)
    store.remove_assignment_membership(
      account_id: account.id,
      inbox_ids: [conversation_data[:inbox_id]],
      label_ids: label_ids_for(account, conversation_data[:cached_label_list]),
      assignee_ids: [conversation_data[:assignee_id]],
      team_ids: [conversation_data[:team_id]],
      conversation_id: conversation_data[:id]
    )
  end

  def label_ids_for(account, label_list)
    label_titles = label_list.to_s.split(',').map(&:strip).compact_blank
    account.labels.pluck(:title, :id).to_h.values_at(*label_titles).compact
  end

  def label_changed?(changed_attributes)
    return false if changed_attributes.blank?

    changed_attributes.key?('label_list') || changed_attributes.key?(:label_list) ||
      changed_attributes.key?('cached_label_list') || changed_attributes.key?(:cached_label_list)
  end

  def store
    ::Conversations::UnreadCounts::Store
  end
end
