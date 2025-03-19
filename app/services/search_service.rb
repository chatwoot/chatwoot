class SearchService
  pattr_initialize [:current_user!, :current_account!, :current_account_user!, :params!, :search_type!]

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
    query = current_account.conversations
    query = query.where(inbox_id: accessable_inbox_ids) unless @current_account_user.administrator?

    @conversations = query.joins('INNER JOIN contacts ON conversations.contact_id = contacts.id')
                          .where("cast(conversations.display_id as text) ILIKE :search OR contacts.name ILIKE :search OR contacts.email
                      ILIKE :search OR contacts.phone_number ILIKE :search OR contacts.identifier ILIKE :search", search: "%#{search_query}%")
                          .order('conversations.created_at DESC')
                          .page(params[:page])
                          .per(15)
  end

  def filter_messages
    @messages = if use_gin_search
                  filter_messages_with_gin
                else
                  filter_messages_with_like
                end
  end

  def filter_messages_with_gin
    base_query = message_base_query

    if search_query.present?
      # Use the @@ operator with to_tsquery for better GIN index utilization
      base_query.where('content @@ to_tsquery(?)', search_query)
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
    query = current_account.messages
    query = query.where(inbox_id: accessable_inbox_ids) unless @current_account_user.administrator?
    query.where('created_at >= ?', 3.months.ago)
  end

  def use_gin_search
    search_query.split.size == 1
  end

  def filter_contacts
    @contacts = current_account.contacts.where(
      "name ILIKE :search OR email ILIKE :search OR phone_number
      ILIKE :search OR identifier ILIKE :search", search: "%#{search_query}%"
    ).resolved_contacts.order_on_last_activity_at('desc').page(params[:page]).per(15)
  end
end
