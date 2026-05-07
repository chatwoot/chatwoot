class Conversations::UnreadCounts::Refresher
  attr_reader :conversation, :changed_attributes

  def initialize(conversation, changed_attributes: nil)
    @conversation = conversation
    @changed_attributes = changed_attributes.is_a?(Hash) ? changed_attributes : {}
  end

  def perform
    return false unless base_ready? || assignment_ready?

    before_memberships = store.memberships_for_keys(affected_cache_keys, conversation.id)
    refresh_base_membership if base_ready?
    refresh_assignment_membership if assignment_ready?
    after_memberships = store.memberships_for_keys(affected_cache_keys, conversation.id)

    before_memberships != after_memberships
  end

  private

  def affected_cache_keys
    keys = []
    keys.concat(affected_base_keys) if base_ready?
    keys.concat(affected_assignment_keys) if assignment_ready?
    keys.uniq
  end

  def affected_base_keys
    affected_inbox_ids.flat_map do |inbox_id|
      [store.inbox_key(account.id, inbox_id)] +
        affected_label_ids.map { |label_id| store.label_inbox_key(account.id, label_id, inbox_id) } +
        affected_team_ids.map { |team_id| store.team_inbox_key(account.id, team_id, inbox_id) }
    end
  end

  def affected_assignment_keys
    affected_inbox_ids.flat_map do |inbox_id|
      affected_assignee_ids.flat_map do |assignee_id|
        assignment_keys_for(inbox_id, assignee_id)
      end
    end
  end

  def assignment_keys_for(inbox_id, assignee_id)
    keys = assignee_id.present? ? assignee_keys_for(inbox_id, assignee_id) : unassigned_keys_for(inbox_id)

    keys + affected_team_ids.map { |team_id| team_assignment_key_for(team_id, inbox_id, assignee_id) }
  end

  def assignee_keys_for(inbox_id, assignee_id)
    [store.inbox_assignee_key(account.id, inbox_id, assignee_id)] +
      affected_label_ids.map { |label_id| store.label_inbox_assignee_key(account.id, label_id, inbox_id, assignee_id) }
  end

  def unassigned_keys_for(inbox_id)
    [store.inbox_unassigned_key(account.id, inbox_id)] +
      affected_label_ids.map { |label_id| store.label_inbox_unassigned_key(account.id, label_id, inbox_id) }
  end

  def refresh_base_membership
    store.remove_base_membership(
      account_id: account.id,
      inbox_ids: affected_inbox_ids,
      label_ids: affected_label_ids,
      team_ids: affected_team_ids,
      conversation_id: conversation.id
    )
    return unless unread?

    store.add_base_membership(
      account_id: account.id,
      inbox_id: conversation.inbox_id,
      label_ids: current_label_ids,
      team_id: conversation.team_id,
      conversation_id: conversation.id
    )
  end

  def refresh_assignment_membership
    store.remove_assignment_membership(
      account_id: account.id,
      inbox_ids: affected_inbox_ids,
      label_ids: affected_label_ids,
      assignee_ids: affected_assignee_ids,
      team_ids: affected_team_ids,
      conversation_id: conversation.id
    )
    return unless unread?

    store.add_assignment_membership(
      account_id: account.id,
      inbox_id: conversation.inbox_id,
      label_ids: current_label_ids,
      assignee_id: conversation.assignee_id,
      team_id: conversation.team_id,
      conversation_id: conversation.id
    )
  end

  def unread?
    return false unless conversation.open?

    incoming_messages = conversation.messages.incoming.where(account_id: account.id)
    if conversation.agent_last_seen_at
      incoming_messages = incoming_messages.where(Message.arel_table[:created_at].gt(conversation.agent_last_seen_at))
    end
    incoming_messages.exists?
  end

  def affected_inbox_ids
    [previous_value_for(:inbox_id), conversation.inbox_id].compact.uniq
  end

  def affected_assignee_ids
    [previous_value_for(:assignee_id), conversation.assignee_id].uniq
  end

  def affected_label_ids
    (previous_label_ids + current_label_ids).uniq
  end

  def affected_team_ids
    [previous_value_for(:team_id), conversation.team_id].compact.uniq
  end

  def previous_label_ids
    label_ids_for(previous_value_for(:label_list) || previous_value_for(:cached_label_list) || conversation.cached_label_list)
  end

  def current_label_ids
    @current_label_ids ||= label_ids_for(conversation.cached_label_list)
  end

  def label_ids_for(label_list)
    labels = label_list.is_a?(Array) ? label_list : label_list.to_s.split(',')
    label_titles = labels.map(&:to_s).map(&:strip).compact_blank
    labels_by_title.values_at(*label_titles).compact
  end

  def previous_value_for(attribute)
    change = changed_attributes[attribute.to_s] || changed_attributes[attribute.to_sym]
    change&.first
  end

  def team_assignment_key_for(team_id, inbox_id, assignee_id)
    return store.team_inbox_assignee_key(account.id, team_id, inbox_id, assignee_id) if assignee_id.present?

    store.team_inbox_unassigned_key(account.id, team_id, inbox_id)
  end

  def labels_by_title
    @labels_by_title ||= account.labels.pluck(:title, :id).to_h
  end

  def base_ready?
    @base_ready ||= store.base_ready?(account.id)
  end

  def assignment_ready?
    @assignment_ready ||= store.assignment_ready?(account.id)
  end

  def account
    conversation.account
  end

  def store
    ::Conversations::UnreadCounts::Store
  end
end
