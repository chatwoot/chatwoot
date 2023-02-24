class TextSearch
  pattr_initialize [:current_user!, :current_account!, :params!]

  DEFAULT_STATUS = 'open'.freeze

  def perform
    {
      messages: filter_messages,
      conversations: filter_conversations,
      contacts: filter_contacts
    }
  end

  private

  def accessable_inbox_ids
    @accessable_inbox_ids ||= @current_user.assigned_inboxes.pluck(:id)
  end

  def filter_conversations
    @conversations = current_account.conversations.where(inbox_id: accessable_inbox_ids).joins('INNER JOIN contacts ON conversations.contact_id = contacts.id')
                                    .where("cast(conversations.display_id as text) LIKE :search OR contacts.name LIKE :search OR contacts.email LIKE :search OR contacts.phone_number
      LIKE :search OR contacts.identifier LIKE :search", search: "%#{params[:q]}%").limit(10)
  end

  def filter_messages
    @messages = current_account.messages.where(inbox_id: accessable_inbox_ids).where('messages.content LIKE :search',
                                                                                     search: "%#{params[:q]}%").limit(10)
  end

  def filter_contacts
    @contacts = current_account.contacts.where(
      "name LIKE :search OR email LIKE :search OR phone_number
      LIKE :search OR identifier LIKE :search", search: "%#{params[:q]}%"
    ).limit(10)
  end
end
