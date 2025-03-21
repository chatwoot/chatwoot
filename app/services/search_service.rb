class SearchService
  pattr_initialize [:current_user!, :current_account!, :params!, :search_type!]

  def perform
    case search_type
    when 'Message'
      { messages: filter_messages }
    when 'Conversation'
      { conversations: filter_conversations }
    when 'Contact'
      { contacts: filter_contacts }
    else
      { contacts: filter_contacts, messages: filter_messages, conversations: filter_conversations }
    end
  end

  private

  def accessable_inbox_ids
    @accessable_inbox_ids ||= @current_user.assigned_inboxes.pluck(:id)
  end

  def search_query
    @search_query ||= params[:q].to_s.strip
  end

  def filter_conversations
    @conversations = current_account.conversations.where(inbox_id: accessable_inbox_ids)
                                    .joins('INNER JOIN contacts ON conversations.contact_id = contacts.id')
                                    .where("cast(conversations.display_id as text) ILIKE :search OR contacts.name ILIKE :search OR contacts.email
                            ILIKE :search OR contacts.phone_number ILIKE :search OR contacts.identifier ILIKE :search", search: "%#{search_query}%")
                                    .order('conversations.created_at DESC')
                                    .page(params[:page])
                                    .per(15)
  end

  def filter_messages
    inbox_ids = accessable_inbox_ids
    time_filter = 3.months.ago
    limit = 15

    @messages = if use_full_text_search?
                  perform_full_text_search(inbox_ids, time_filter, limit)
                else
                  perform_like_search(inbox_ids, time_filter, limit)
                end

    @messages
  end

  def use_full_text_search?
    ActiveRecord::Base.connection.column_exists?(:messages, :content_tsvector)
  end

  def perform_full_text_search(inbox_ids, time_filter, limit)
    # First try exact match
    exact_tsquery = prepare_tsquery(search_query, exact: true)
    messages = execute_search_query(exact_tsquery, inbox_ids, time_filter, limit)

    # If no results found, try with wildcard match
    if messages.empty?
      wildcard_tsquery = prepare_tsquery(search_query, exact: false)
      messages = execute_search_query(wildcard_tsquery, inbox_ids, time_filter, limit)
    end

    messages
  end

  def perform_like_search(inbox_ids, time_filter, limit)
    current_account.messages
                   .where(inbox_id: inbox_ids)
                   .where('created_at >= ?', time_filter)
                   .where('messages.content ILIKE :search', search: "%#{search_query}%")
                   .reorder('created_at DESC')
                   .page(params[:page]).per(limit)
  end

  def execute_search_query(tsquery, inbox_ids, time_filter, limit)
    cte_query = build_search_cte_query
    query_params = build_search_query_params(tsquery, inbox_ids, time_filter, limit)

    Message.find_by_sql([cte_query, query_params])
  end

  def build_search_cte_query
    <<-SQL.squish
      WITH text_search_results AS (
        SELECT id
        FROM messages
        WHERE content_tsvector @@ to_tsquery('english', :tsquery)
        AND inbox_id IN (:inbox_ids)
        LIMIT 1000
      )
      SELECT m.*
      FROM messages m
      JOIN text_search_results tsr ON m.id = tsr.id
      WHERE m.account_id = :account_id
      AND m.created_at >= :time_filter
      ORDER BY m.created_at DESC
      LIMIT :limit OFFSET :offset
    SQL
  end

  def build_search_query_params(tsquery, inbox_ids, time_filter, limit)
    {
      tsquery: tsquery,
      inbox_ids: inbox_ids,
      account_id: current_account.id,
      time_filter: time_filter,
      limit: limit,
      offset: ((params[:page].to_i - 1) * limit).clamp(0, Float::INFINITY)
    }
  end

  def prepare_tsquery(query, exact: false)
    return '' if query.blank?

    # Create tsquery format with & (AND) between words
    tsquery = query.gsub(/\s+/, ' & ')

    # For exact search, don't add wildcards
    if exact
      tsquery
    elsif tsquery.include?('&')
      terms = tsquery.split(' & ')
      "#{terms[0..-2].join(' & ')} & #{terms[-1]}:*"
    # Wrap with :* for prefix matching on the last term
    else
      "#{tsquery}:*"
    end
  end

  def filter_contacts
    @contacts = current_account.contacts.where(
      "name ILIKE :search OR email ILIKE :search OR phone_number
      ILIKE :search OR identifier ILIKE :search", search: "%#{search_query}%"
    ).resolved_contacts.order_on_last_activity_at('desc').page(params[:page]).per(15)
  end
end
