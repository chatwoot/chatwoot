class TextSearch
  pattr_initialize [:current_user!, :current_account!, :params!]

  DEFAULT_STATUS = 'open'.freeze

  def perform
    set_inboxes
    {
      contacts: filter_contacts,
      messages: filter_messages,
      conversations: filter_conversations
    }
  end

  def set_inboxes
    @inbox_ids = @current_user.assigned_inboxes.pluck(:id)
  end

  private

  def filter_conversations
    @conversations = PgSearch.multisearch((@params[:q]).to_s).where(
      account_id: @current_account.id, searchable_type: 'Conversation'
    ).joins("INNER JOIN conversations ON pg_search_documents.searchable_id = conversations.id
      AND conversations.inbox_id IN (#{@inbox_ids.join(',')})").includes(:searchable).limit(20).collect(&:searchable)
  end

  def filter_messages
    @messages = PgSearch.multisearch((@params[:q]).to_s).where(
      account_id: @current_account.id, searchable_type: 'Message'
    ).joins("INNER JOIN messages ON pg_search_documents.searchable_id = messages.id
      AND messages.inbox_id IN (#{@inbox_ids.join(',')})").includes(:searchable).limit(20).collect(&:searchable)
    # @messages = Message.where(account_id: @current_account.id, inbox_id: @inbox_ids, message_type: [:incoming, :outgoing]).where.not(
    #   id: [305347, 1910988, 1953590, 4485918, 5730758, 5858699, 5908520, 5936813, 5987708, 6009638, 6028365, 6082901, 6304243]
    #   ).text_search(@params[:q]).limit(20)
  end

  def filter_contacts
    @contacts = PgSearch.multisearch((@params[:q]).to_s).where(
      account_id: @current_account.id, searchable_type: 'Contact'
    ).joins('INNER JOIN contacts ON pg_search_documents.searchable_id = contacts.id').includes(:searchable).limit(20).collect(&:searchable)
    # @contacts = Contact.where(account_id: @current_account.id).text_search(@params[:q]).limit(20)
  end
end
