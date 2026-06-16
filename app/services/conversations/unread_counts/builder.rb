class Conversations::UnreadCounts::Builder
  PARTICIPATING_PERMISSION = 'conversation_participating_manage'.freeze
  RELATIVE_DATE_FILTER_OPERATOR = 'days_before'.freeze
  BATCH_SIZE = 1000
  FILTER_ERRORS = [
    ActiveRecord::StatementInvalid,
    CustomExceptions::CustomFilter::InvalidAttribute,
    CustomExceptions::CustomFilter::InvalidOperator,
    CustomExceptions::CustomFilter::InvalidQueryOperator,
    CustomExceptions::CustomFilter::InvalidValue
  ].freeze

  attr_reader :account

  def initialize(account)
    @account = account
  end

  def build_base!
    store.clear_account!(account.id)
    write_memberships(assignment: false)
    store.mark_base_ready!(account.id)
  end

  def build_assignment!
    store.clear_assignment!(account.id)
    write_memberships(assignment: true)
    store.mark_assignment_ready!(account.id)
  end

  def build_all!
    build_base!
    build_assignment!
  end

  def build_filters_for!(user)
    store.clear_user_filters!(account.id, user.id)
    version_snapshot = store.filter_version_snapshot(account.id, user.id)
    custom_filters = conversation_custom_filters(user).to_a

    store.add_filter_memberships(
      account_id: account.id,
      user_id: user.id,
      filters: {
        mentions: mentioned_unread_conversation_ids(user),
        participating: participating_unread_conversation_ids(user),
        unattended: unattended_unread_conversation_ids(user)
      },
      folders: folder_unread_conversation_ids(custom_filters, user)
    )
    mark_filters_ready_if_current(user, custom_filters, version_snapshot)
  end

  private

  def mark_filters_ready_if_current(user, custom_filters, version_snapshot)
    store.mark_filters_ready_if_current!(
      account.id,
      user.id,
      version_snapshot: version_snapshot,
      expires_in: filters_ready_ttl(custom_filters)
    )
  end

  def write_memberships(assignment:)
    unread_conversations(open_only: true).in_batches(of: BATCH_SIZE) do |relation|
      columns = %i[id inbox_id assignee_id cached_label_list team_id]
      memberships = relation.pluck(*columns).map do |id, inbox_id, assignee_id, cached_label_list, team_id|
        {
          conversation_id: id,
          inbox_id: inbox_id,
          assignee_id: assignee_id,
          team_id: team_id,
          label_ids: label_ids_for(cached_label_list)
        }
      end

      store.add_memberships(account_id: account.id, memberships: memberships, assignment: assignment)
    end
  end

  def mentioned_unread_conversation_ids(user)
    visible_unread_conversations(user, open_only: true)
      .joins(:mentions)
      .where(mentions: { account_id: account.id, user_id: user.id })
      .pluck(:id)
  end

  def participating_unread_conversation_ids(user)
    participating_visible_unread_conversations(user, open_only: true)
      .where(id: user.participating_conversations.where(account_id: account.id).select(:id))
      .pluck(:id)
  end

  def unattended_unread_conversation_ids(user)
    visible_unread_conversations(user, open_only: true)
      .unattended
      .pluck(:id)
  end

  def folder_unread_conversation_ids(custom_filters, user)
    custom_filters.each_with_object({}) do |custom_filter, result|
      result[custom_filter.id] = unread_ids_for_filter(custom_filter, user)
    rescue *FILTER_ERRORS
      next
    end
  end

  def conversation_custom_filters(user)
    account.custom_filters.where(user: user, filter_type: :conversation)
  end

  def filters_ready_ttl(custom_filters)
    return Conversations::UnreadCounts::READY_TTL unless relative_date_filter?(custom_filters)

    seconds_until_next_day
  end

  def relative_date_filter?(custom_filters)
    custom_filters.any? do |custom_filter|
      Array(custom_filter.query.with_indifferent_access[:payload]).any? do |condition|
        condition[:filter_operator] == RELATIVE_DATE_FILTER_OPERATOR
      end
    end
  end

  def seconds_until_next_day
    [(Time.zone.tomorrow.beginning_of_day - Time.current).ceil, 1].max
  end

  def unread_ids_for_filter(custom_filter, user)
    filter_relation = ::Conversations::FilterService.new(custom_filter.query.with_indifferent_access, user, account).filtered_relation
    filter_relation
      .where(id: unread_conversations(open_only: false).select(:id))
      .reorder(nil)
      .distinct
      .pluck(:id)
  end

  def unread_conversations(open_only:)
    conversations = account.conversations
    conversations = conversations.open if open_only

    conversations.joins(:messages)
                 .merge(Message.incoming.reorder(nil))
                 .where(messages: { account_id: account.id })
                 .where(unread_since_last_seen_condition)
                 .distinct
  end

  def visible_unread_conversations(user, open_only:)
    ::Conversations::PermissionFilterService.new(unread_conversations(open_only: open_only), user, account).perform
  end

  def participating_visible_unread_conversations(user, open_only:)
    return inbox_visible_unread_conversations(user, open_only: open_only) if custom_role_participating_permission?(user)

    visible_unread_conversations(user, open_only: open_only)
  end

  def inbox_visible_unread_conversations(user, open_only:)
    conversations = unread_conversations(open_only: open_only)
    return conversations if account_user_for(user)&.administrator?

    conversations.where(inbox: user.inboxes.where(account_id: account.id))
  end

  def custom_role_participating_permission?(user)
    account_user = account_user_for(user)
    account_user&.agent? && account_user.custom_role_id.present? && account_user.permissions.include?(PARTICIPATING_PERMISSION)
  end

  def account_user_for(user)
    account.account_users.find_by(user_id: user.id)
  end

  def unread_since_last_seen_condition
    conversations = Conversation.arel_table
    messages = Message.arel_table

    conversations[:agent_last_seen_at].eq(nil).or(messages[:created_at].gt(conversations[:agent_last_seen_at]))
  end

  def label_ids_for(cached_label_list)
    label_titles = cached_label_list.to_s.split(',').map(&:strip).compact_blank
    labels_by_title.values_at(*label_titles).compact
  end

  def labels_by_title
    @labels_by_title ||= account.labels.pluck(:title, :id).to_h
  end

  def store
    ::Conversations::UnreadCounts::Store
  end
end
