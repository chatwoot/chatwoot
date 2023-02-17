class TextSearch
  pattr_initialize [:current_user!, :current_account!, :params!, :search_type!]

  DEFAULT_STATUS = 'open'.freeze

  def perform
    set_inboxes
    case search_type
    when 'Message'
      { messages: filter_messages }
    when 'Conversation'
      { conversations: filter_conversations }
    when 'Contact'
      { contacts: 'filter_contacts' }
    else
      { contacts: 'filter_contacts' }
    end
  end

  def set_inboxes
    @inbox_ids = @current_user.assigned_inboxes.pluck(:id)
  end

  private

  def filter_conversations
    @conversations = PgSearch.multisearch((@params[:q]).to_s).where(
      "pg_search_documents.account_id = #{@current_account.id} AND searchable_type = 'Conversation' AND pg_search_documents.updated_at > ?", last_six_month
    ).joins("INNER JOIN conversations
      ON pg_search_documents.searchable_id = conversations.id
      AND conversations.inbox_id IN (#{@inbox_ids.join(',')})
      AND conversations.account_id = #{@current_account.id}").includes(:searchable).limit(20).collect(&:searchable)
  end

  def filter_messages
    @messages = PgSearch.multisearch((@params[:q]).to_s).where(
      "pg_search_documents.account_id = #{@current_account.id} AND searchable_type = 'Message' AND pg_search_documents.updated_at > ?", last_six_month
    ).joins("INNER JOIN messages ON pg_search_documents.searchable_id = messages.id
      AND messages.inbox_id IN (#{@inbox_ids.join(',')})
      AND messages.account_id = #{@current_account.id}
      AND pg_search_documents.updated_at > #{last_six_month}"
    ).includes(:searchable).limit(20).collect(&:searchable)
  end

  def filter_contacts
    @contacts = PgSearch.multisearch((@params[:q]).to_s).where(
      "pg_search_documents.account_id = #{@current_account.id} AND searchable_type = 'Contact' AND pg_search_documents.updated_at > ?", last_six_month
    ).joins("INNER JOIN contacts ON pg_search_documents.searchable_id = contacts.id
      AND contacts.account_id = #{@current_account.id}
      AND pg_search_documents.updated_at > #{last_six_month}"
    ).includes(:searchable).limit(20).collect(&:searchable)
  end

  def last_six_month
    (Time.current - 6.months)
  end
end
