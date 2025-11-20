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
    base_query = current_account.conversations.where(inbox_id: accessable_inbox_ids)

    # If search query starts with #, do ID-only exact match (no fallback to other fields)
    # Example: #123 -> only search display_id = 123
    if search_query.match?(/^#(\d+)$/)
      conversation_id = search_query.match(/^#(\d+)$/)[1].to_i
      @conversations = base_query.where('conversations.display_id = ?', conversation_id)
                                 .order('conversations.created_at DESC')
                                 .page(params[:page])
                                 .per(15)
    # If search query is numeric only (without #), do exact match on display_id
    elsif search_query.match?(/^\d+$/)
      @conversations = base_query.joins('INNER JOIN contacts ON conversations.contact_id = contacts.id')
                                 .where('conversations.display_id = ?', search_query.to_i)
                                 .order('conversations.created_at DESC')
                                 .page(params[:page])
                                 .per(15)
    # Otherwise, search across all fields
    else
      @conversations = base_query.joins('INNER JOIN contacts ON conversations.contact_id = contacts.id')
                                 .where("cast(conversations.display_id as text) ILIKE :search OR contacts.name ILIKE :search OR contacts.email
                            ILIKE :search OR contacts.phone_number ILIKE :search OR contacts.identifier ILIKE :search", search: "%#{search_query}%")
                                 .order('conversations.created_at DESC')
                                 .page(params[:page])
                                 .per(15)
    end
  end

  def filter_messages
    @messages = if use_gin_search
                  filter_messages_with_gin
                elsif should_run_advanced_search?
                  advanced_search
                else
                  filter_messages_with_like
                end
  end

  def should_run_advanced_search?
    ChatwootApp.advanced_search_allowed? && current_account.feature_enabled?('advanced_search')
  end

  def advanced_search; end

  def filter_messages_with_gin
    base_query = message_base_query

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
    message_base_query
      .where('messages.content ILIKE :search', search: "%#{search_query}%")
      .reorder('created_at DESC')
      .page(params[:page])
      .per(15)
  end

  def message_base_query
    query = current_account.messages.where('created_at >= ?', 3.months.ago)
    query = query.where(inbox_id: accessable_inbox_ids) unless should_skip_inbox_filtering?
    query
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
    @contacts = current_account.contacts.where(
      "name ILIKE :search OR email ILIKE :search OR phone_number
      ILIKE :search OR identifier ILIKE :search", search: "%#{search_query}%"
    ).resolved_contacts(
      use_crm_v2: current_account.feature_enabled?('crm_v2')
    ).order_on_last_activity_at('desc').page(params[:page]).per(15)
  end

  def filter_articles
    @articles = current_account.articles
                               .text_search(search_query)
                               .page(params[:page])
                               .per(15)
  end
end

SearchService.prepend_mod_with('SearchService')
