class Conversations::FilterService < FilterService
  ATTRIBUTE_MODEL = 'conversation_attribute'.freeze
  USER_LINK_TABLES = { 'participant_id' => 'conversation_participants', 'mentioned_user_id' => 'mentions' }.freeze
  # Same condition as Conversation.unattended
  UNATTENDED_CONDITION = '(conversations.first_reply_created_at IS NULL OR conversations.waiting_since IS NOT NULL)'.freeze

  def initialize(params, user, account)
    @account = account
    super(params, user)
  end

  def perform
    validate_query_operator
    @conversations = query_builder(@filters['conversations'])
    mine_count, unassigned_count, all_count, = set_count_for_all_conversations
    assigned_count = all_count - unassigned_count

    {
      conversations: conversations,
      count: {
        mine_count: mine_count,
        assigned_count: assigned_count,
        unassigned_count: unassigned_count,
        all_count: all_count
      }
    }
  end

  def base_relation
    # :messages is deliberately not preloaded: the list payload fetches messages through
    # scoped queries (last message, last_non_activity_message), which bypass the preload.
    conversations = @account.conversations.includes(
      :taggings, { assignee: { avatar_attachment: [:blob] } }, { contact: { avatar_attachment: [:blob] } }, :team,
      :contact_inbox
    ).preload(
      inbox: :channel,
      ai_assignee: { avatar_attachment: [:blob] }
    )

    Conversations::PermissionFilterService.new(
      conversations,
      @user,
      @account,
      plan_hint_selective_filter: label_filter_present?
    ).perform
  end

  def current_page
    @params[:page] || 1
  end

  def filter_config
    {
      entity: 'Conversation',
      table_name: 'conversations'
    }
  end

  def conversations
    Conversations::SortService.apply(@conversations, @params[:sort_by]).page(current_page)
  end

  private

  def handle_standard_attributes(current_filter, query_hash, current_index, filter_operator_value)
    return unattended_filter_query(query_hash) if query_hash[:attribute_key] == 'unattended'

    user_link_table = USER_LINK_TABLES[query_hash[:attribute_key]]
    return user_link_filter_query(user_link_table, query_hash, current_index) if user_link_table

    super
  end

  # Matches conversations that the given users are linked to through a join table, such as participants or mentions.
  def user_link_filter_query(table_name, query_hash, current_index)
    user_link_query = "SELECT 1 FROM #{table_name} WHERE #{table_name}.conversation_id = conversations.id " \
                      "AND #{table_name}.user_id IN (:value_#{current_index})"
    exists_operator = query_hash[:filter_operator] == 'not_equal_to' ? 'NOT EXISTS' : 'EXISTS'

    "#{exists_operator} (#{user_link_query}) #{query_hash[:query_operator]}"
  end

  def unattended_filter_query(query_hash)
    values = Array.wrap(query_hash[:values])
    unless values.length == 1 && values.first.in?([true, false])
      raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: query_hash[:attribute_key])
    end

    unattended = values.first == (query_hash[:filter_operator] == 'equal_to')
    "#{'NOT ' unless unattended}#{UNATTENDED_CONDITION} #{query_hash[:query_operator]}"
  end

  # The planner hint only pays off when the label condition positively narrows the
  # result set: `equal_to` joined by AND. Negative/presence operators or an OR in the
  # payload leave the result broad, where the inbox index is the better driver.
  def label_filter_present?
    payload = @params[:payload].to_a
    return false if payload.any? { |query_hash| query_hash[:query_operator].to_s.casecmp('or').zero? }

    payload.any? { |query_hash| query_hash[:attribute_key] == 'labels' && query_hash[:filter_operator] == 'equal_to' }
  end
end
