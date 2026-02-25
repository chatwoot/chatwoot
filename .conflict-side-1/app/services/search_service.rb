class SearchService
  pattr_initialize [:current_user!, :current_account!, :params!, :search_type!]

  def account_user
    @account_user ||= current_account.account_users.find_by(user: current_user)
  end

  def perform
    case search_type
    when 'Message'
      { messages: filter_messages }
    when 'Conversation'
      { conversations: filter_conversations }
    when 'Contact'
      { contacts: filter_contacts }
    when 'Article'
      { articles: filter_articles }
    else
      { contacts: filter_contacts, messages: filter_messages, conversations: filter_conversations, articles: filter_articles }
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
    conversations_query = current_account.conversations.where(inbox_id: accessable_inbox_ids)
                                         .joins('INNER JOIN contacts ON conversations.contact_id = contacts.id')
                                         .where("cast(conversations.display_id as text) ILIKE :search OR contacts.name ILIKE :search OR contacts.email
                            ILIKE :search OR contacts.phone_number ILIKE :search OR contacts.identifier ILIKE :search", search: "%#{search_query}%")

    if current_account.feature_enabled?('advanced_search')
      conversations_query = apply_time_filter(conversations_query,
                                              'conversations.last_activity_at')
    end

    @conversations = conversations_query.order('conversations.created_at DESC')
                                        .page(params[:page])
                                        .per(15)
  end

  def filter_messages
    @messages = if use_gin_search
                  filter_messages_with_gin
                elsif should_run_advanced_search?
                  advanced_search_with_fallback
                else
                  filter_messages_with_like
                end
  end

  def advanced_search_with_fallback
    advanced_search
  rescue Faraday::ConnectionFailed, Searchkick::Error, Elasticsearch::Transport::Transport::Error => e
    Rails.logger.warn("Elasticsearch unavailable, falling back to SQL search: #{e.message}")
    use_gin_search ? filter_messages_with_gin : filter_messages_with_like
  end

  def should_run_advanced_search?
    ChatwootApp.advanced_search_allowed? && current_account.feature_enabled?('advanced_search')
  end

  def advanced_search; end

  def filter_messages_with_gin
    base_query = message_base_query
    base_query = apply_message_filters(base_query)

    if search_query.present?
      # Use the @@ operator with to_tsquery for better GIN index utilization
      # Convert search query to tsquery format with prefix matching

      # Use this if we wanna match splitting the words
      # split_query = search_query.split.map { |term| "#{term} | #{term}:*" }.join(' & ')

      # This will do entire sentence matching using phrase distance operator
      tsquery = search_query.split.join(' <-> ')

      # Apply the text search using the GIN index
      base_query.where('content @@ to_tsquery(?)', tsquery)
                .reorder('created_at DESC')
                .page(params[:page])
                .per(15)
    else
      base_query.reorder('created_at DESC')
                .page(params[:page])
                .per(15)
    end
  end

  def filter_messages_with_like
    base_query = message_base_query
    base_query = apply_message_filters(base_query)
    base_query.where('messages.content ILIKE :search', search: "%#{search_query}%")
              .reorder('created_at DESC')
              .page(params[:page])
              .per(15)
  end

  def message_base_query
    query = current_account.messages.where('created_at >= ?', 3.months.ago)
    query = query.where(inbox_id: accessable_inbox_ids) unless should_skip_inbox_filtering?
    query
  end

  def apply_message_filters(query)
    return query unless current_account.feature_enabled?('advanced_search')

    query = apply_time_filter(query, 'messages.created_at')
    query = apply_sender_filter(query)
    apply_inbox_id_filter(query)
  end

  def apply_sender_filter(query)
    sender_type, sender_id = parse_from_param(params[:from])
    return query unless sender_type && sender_id

    query.where(sender_type: sender_type, sender_id: sender_id)
  end

  def parse_from_param(from_param)
    return [nil, nil] unless from_param&.match?(/\A(contact|agent):\d+\z/)

    type, id = from_param.split(':')
    sender_type = type == 'agent' ? 'User' : 'Contact'
    [sender_type, id.to_i]
  end

  def apply_inbox_id_filter(query)
    return query if params[:inbox_id].blank?

    inbox_id = params[:inbox_id].to_i
    return query if inbox_id.zero?
    return query unless validate_inbox_access(inbox_id)

    query.where(inbox_id: inbox_id)
  end

  def validate_inbox_access(inbox_id)
    return true if should_skip_inbox_filtering?

    accessable_inbox_ids.include?(inbox_id)
  end

  def should_skip_inbox_filtering?
    account_user.administrator? || user_has_access_to_all_inboxes?
  end

  def user_has_access_to_all_inboxes?
    accessable_inbox_ids.sort == current_account.inboxes.pluck(:id).sort
  end

  def use_gin_search
    current_account.feature_enabled?('search_with_gin')
  end

  def filter_contacts
    contacts_query = current_account.contacts.where(
      "name ILIKE :search OR email ILIKE :search OR phone_number
      ILIKE :search OR identifier ILIKE :search", search: "%#{search_query}%"
    )

    contacts_query = apply_time_filter(contacts_query, 'last_activity_at') if current_account.feature_enabled?('advanced_search')

    @contacts = contacts_query.resolved_contacts(
      use_crm_v2: current_account.feature_enabled?('crm_v2')
    ).order_on_last_activity_at('desc').page(params[:page]).per(15)
  end

  def filter_articles
    articles_query = current_account.articles.text_search(search_query)
    articles_query = apply_time_filter(articles_query, 'updated_at') if current_account.feature_enabled?('advanced_search')

    @articles = articles_query.page(params[:page]).per(15)
  end

  def apply_time_filter(query, column_name)
    return query if params[:since].blank? && params[:until].blank?

    query = query.where("#{column_name} >= ?", cap_since_time(params[:since])) if params[:since].present?
    query = query.where("#{column_name} <= ?", cap_until_time(params[:until])) if params[:until].present?
    query
  end

  def cap_since_time(since_param)
    max_lookback = 90.days.ago
    requested_time = Time.zone.at(since_param.to_i)

    # Silently cap to max_lookback if requested time is too far back
    [requested_time, max_lookback].max
  end

  def cap_until_time(until_param)
    max_future = 90.days.from_now
    requested_time = Time.zone.at(until_param.to_i)

    [requested_time, max_future].min
  end
end

SearchService.prepend_mod_with('SearchService')
