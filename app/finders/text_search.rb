class TextSearch
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

  def filter_conversations
    @conversations = current_account.conversations.where(inbox_id: accessable_inbox_ids)
                                    .joins('INNER JOIN contacts ON conversations.contact_id = contacts.id')
                                    .where("cast(conversations.display_id as text) LIKE :search OR contacts.name LIKE :search OR contacts.email
                            LIKE :search OR contacts.phone_number LIKE :search OR contacts.identifier LIKE :search", search: "%#{params[:q]}%")
                                    .limit(10)
  end

  def filter_messages
    @messages = current_account.messages.where(inbox_id: accessable_inbox_ids)
                               .where('messages.content LIKE :search', search: "%#{params[:q]}%")
                               .where('created_at >= ?', 3.months.ago).limit(10)
  end

  def filter_contacts
    @contacts = current_account.contacts.where(
      "name LIKE :search OR email LIKE :search OR phone_number
      LIKE :search OR identifier LIKE :search", search: "%#{params[:q]}%"
    ).limit(10)
  end
end
