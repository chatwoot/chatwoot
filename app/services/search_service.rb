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
                                    .limit(10)
  end

  def filter_messages
    @messages = current_account.messages.where(inbox_id: accessable_inbox_ids)
                               .where('messages.content ILIKE :search', search: "%#{search_query}%")
                               .where('created_at >= ?', 3.months.ago)
                               .reorder('created_at DESC')
                               .limit(10)
  end

  def filter_contacts
    @contacts = current_account.contacts.where(
      "name ILIKE :search OR email ILIKE :search OR phone_number
      ILIKE :search OR identifier ILIKE :search", search: "%#{search_query}%"
    ).resolved_contacts.order_on_last_activity_at('desc').limit(10)
  end
end
