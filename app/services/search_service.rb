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
    query = current_account.conversations.where(inbox_id: accessable_inbox_ids)
                           .joins('INNER JOIN contacts ON conversations.contact_id = contacts.id')
                           .where("cast(conversations.display_id as text) ILIKE :search OR contacts.name ILIKE :search OR contacts.email
                   ILIKE :search OR contacts.phone_number ILIKE :search OR contacts.identifier ILIKE :search OR
                   contacts.additional_attributes->'social_profiles'->>'instagram' ILIKE :search OR
                   contacts.additional_attributes->>'social_instagram_user_name' ILIKE :search", search: "%#{search_query}%")

    # Filter conversations where agent is conversation assignee OR contact owner
    if contact_assignment_enabled? && !current_user_admin?
      query = query.where('conversations.assignee_id = ? OR contacts.assignee_id = ?', current_user.id, current_user.id)
    end

    @conversations = query.order('conversations.created_at DESC')
                          .limit(10)
  end

  def filter_messages
    query = current_account.messages.where(inbox_id: accessable_inbox_ids)
                           .where('messages.content ILIKE :search', search: "%#{search_query}%")
                           .where('created_at >= ?', 3.months.ago)

    # Filter messages where agent is conversation assignee OR contact owner
    if contact_assignment_enabled? && !current_user_admin?
      query = query.joins(conversation: :contact)
                   .where('conversations.assignee_id = ? OR contacts.assignee_id = ?', current_user.id, current_user.id)
    end

    @messages = query.reorder('created_at DESC')
                     .limit(10)
  end

  def filter_contacts
    query = current_account.contacts
                           .where(search_conditions)
                           .where(non_empty_conditions)

    # Filter by assignee if contact assignment feature is enabled and user is not admin
    query = query.where('assignee_id = ? OR assignee_id IS NULL', current_user.id) if contact_assignment_enabled? && !current_user_admin?

    @contacts = query.order(Arel.sql('contacts.last_activity_at DESC NULLS LAST'))
                     .limit(10)
  end

  def search_conditions
    [
      "COALESCE(name, '') ILIKE :search OR
      COALESCE(email, '') ILIKE :search OR
      COALESCE(phone_number, '') ILIKE :search OR
      COALESCE(identifier, '') ILIKE :search OR
      COALESCE(additional_attributes->'social_profiles'->>'instagram', '') ILIKE :search OR
      COALESCE(additional_attributes->>'social_instagram_user_name', '') ILIKE :search",
      { search: "%#{search_query}%" }
    ]
  end

  def non_empty_conditions
    "COALESCE(email, '') <> '' OR
    COALESCE(phone_number, '') <> '' OR
    COALESCE(identifier, '') <> '' OR
    COALESCE(additional_attributes->'social_profiles'->>'instagram', '') <> '' OR
    COALESCE(additional_attributes->>'social_instagram_user_name', '') <> ''"
  end

  def contact_assignment_enabled?
    current_account.custom_attributes&.dig('enable_contact_assignment') == true
  end

  def current_user_admin?
    current_user.account_users.find_by(account_id: current_account.id)&.administrator?
  end
end
