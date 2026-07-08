class Conversations::UnreadCounts::Listener < BaseListener
  include Events::Types

  FILTERED_CONVERSATION_UPDATE_KEYS = %w[
    additional_attributes cached_label_list campaign_id custom_attributes first_reply_created_at label_list last_activity_at priority snoozed_until
    waiting_since
  ].freeze
  private_constant :FILTERED_CONVERSATION_UPDATE_KEYS

  def message_created(event)
    message, = extract_message_and_account(event)
    account = message.account
    return unless account.feature_enabled?('conversation_unread_counts') || account.feature_enabled?(filtered_count_feature_flag)

    conversation = message.conversation
    refreshed = refresh(conversation) if message.incoming? && account.feature_enabled?('conversation_unread_counts')

    invalidate_filtered_conversation(conversation)

    notify_filtered_count_change(conversation) unless message.incoming? && refreshed
  end

  def conversation_status_changed(event)
    conversation, = extract_conversation_and_account(event)
    refresh_then_invalidate(conversation, event.data[:changed_attributes])
  end

  def conversation_updated(event)
    conversation, = extract_conversation_and_account(event)
    changed_attributes = event.data[:changed_attributes]
    notify_filtered_count_change(conversation) if filtered_conversation_update_changed?(changed_attributes) && !label_changed?(changed_attributes)
    return unless label_changed?(changed_attributes)

    refresh(conversation, changed_attributes)
  end

  def conversation_contact_changed(event)
    conversation, = extract_conversation_and_account(event)
    invalidate_filtered_conversation(conversation)
    notify_filtered_count_change(conversation)
  end

  def assignee_changed(event)
    conversation, = extract_conversation_and_account(event)
    refresh_then_invalidate(conversation, event.data[:changed_attributes])
  end

  def team_changed(event)
    conversation, = extract_conversation_and_account(event)
    refresh_then_invalidate(conversation, event.data[:changed_attributes])
  end

  def conversation_mentioned(event)
    conversation, = extract_conversation_and_account(event)
    user = event.data[:user]
    filtered_count_invalidator(conversation.account).user_visibility_changed!(user_id: user&.id)
  end

  def conversation_deleted(event)
    conversation_data = event.data[:conversation_data]&.with_indifferent_access
    return if conversation_data.blank?

    account = Account.find_by(id: conversation_data[:account_id])
    return if account.blank?

    removed = account.feature_enabled?('conversation_unread_counts') && remove_deleted_conversation(account, conversation_data)
    filtered_count_invalidator(account).conversation_changed!
    return notify_deleted_filtered_count_change(account, conversation_data) unless removed

    Rails.configuration.dispatcher.dispatch(CONVERSATION_UNREAD_COUNT_CHANGED, Time.zone.now, conversation_data: conversation_data.to_h)
  end

  private

  def refresh_then_invalidate(conversation, changed_attributes = nil)
    refreshed = refresh(conversation, changed_attributes)
    invalidate_filtered_conversation(conversation)
    notify_filtered_count_change(conversation) unless refreshed
  end

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

  def filtered_conversation_update_changed?(changed_attributes)
    return false if changed_attributes.blank?

    changed_attributes.keys.map(&:to_s).intersect?(FILTERED_CONVERSATION_UPDATE_KEYS)
  end

  def invalidate_filtered_conversation(conversation)
    filtered_count_invalidator(conversation.account).conversation_changed!
  end

  def notify_filtered_count_change(conversation)
    return unless conversation.account.feature_enabled?('conversation_unread_counts')
    return unless conversation.account.feature_enabled?(filtered_count_feature_flag)

    Rails.configuration.dispatcher.dispatch(CONVERSATION_UNREAD_COUNT_CHANGED, Time.zone.now, conversation: conversation)
  end

  def notify_deleted_filtered_count_change(account, conversation_data)
    return unless account.feature_enabled?(filtered_count_feature_flag)

    Rails.configuration.dispatcher.dispatch(CONVERSATION_UNREAD_COUNT_CHANGED, Time.zone.now, conversation_data: conversation_data.to_h)
  end

  def filtered_count_invalidator(account)
    ::Conversations::UnreadCounts::FilteredCountInvalidator.new(account)
  end

  def filtered_count_feature_flag
    ::Conversations::UnreadCounts::FilteredCountInvalidator::FEATURE_FLAG
  end

  def store
    ::Conversations::UnreadCounts::Store
  end
end
