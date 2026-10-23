class Conversations::FilterService < FilterService
  ATTRIBUTE_MODEL = 'conversation_attribute'.freeze

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
    case query_hash[:attribute_key]
    when 'unattended' then unattended_filter_query(query_hash)
    when 'participant_id' then user_link_filter_query(ConversationParticipant, query_hash)
    when 'mentioned_user_id' then user_link_filter_query(Mention, query_hash)
    else super
    end
  end

  # Matches conversations that the given users are linked to through a join model, such as participants or mentions.
  def user_link_filter_query(link_model, query_hash)
    user_ids = Array.wrap(query_hash[:values])
    raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: query_hash[:attribute_key]) unless user_ids.all?(Integer)

    linked_conversation_ids = link_model.where(user_id: user_ids).select(:conversation_id)
    conversations = Conversation.where(id: linked_conversation_ids)
    conversations = conversations.invert_where if query_hash[:filter_operator] == 'not_equal_to'
    "#{condition_sql(conversations)} #{query_hash[:query_operator]}"
  end

  def unattended_filter_query(query_hash)
    values = Array.wrap(query_hash[:values])
    unless values.length == 1 && values.first.in?([true, false])
      raise CustomExceptions::CustomFilter::InvalidValue.new(attribute_name: query_hash[:attribute_key])
    end

    "#{'NOT ' unless values.first}#{condition_sql(Conversation.unattended)} #{query_hash[:query_operator]}"
  end

  # Filter conditions are joined as SQL strings, so render a relation's condition with its values inlined.
  def condition_sql(relation)
    connection = relation.connection
    connection.unprepared_statement { connection.to_sql(relation.where_clause.ast) }
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
