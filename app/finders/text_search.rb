class TextSearch
  attr_reader :current_user, :current_account, :params

  DEFAULT_STATUS = 'open'.freeze

  def initialize(current_user, params)
    @current_user = current_user
    @current_account = @current_user.account || Current.account
    @params = params
  end

  def perform
    set_inboxes
    {
      messages: filter_messages,
      conversations: filter_conversations,
      contacts: filter_contacts
    }
  end

  def set_inboxes
    @inbox_ids = @current_user.assigned_inboxes.pluck(:id)
  end

  private

  def filter_conversations
    @conversations = PgSearch.multisearch((@params[:q]).to_s).where(
      inbox_id: @inbox_ids, account_id: @current_account, searchable_type: 'Conversation'
    ).joins('INNER JOIN conversations ON pg_search_documents.searchable_id = conversations.id').includes(:searchable).limit(20).collect(&:searchable)
  end

  def filter_messages
    @messages = PgSearch.multisearch((@params[:q]).to_s).where(
      inbox_id: @inbox_ids, account_id: @current_account, searchable_type: 'Message'
    ).joins('INNER JOIN messages ON pg_search_documents.searchable_id = messages.id').includes(:searchable).limit(20).collect(&:searchable)
  end

  def filter_contacts
    @contacts = PgSearch.multisearch((@params[:q]).to_s).where(
      account_id: @current_account, searchable_type: 'Contact'
    ).joins('INNER JOIN contacts ON pg_search_documents.searchable_id = contacts.id').includes(:searchable).limit(20).collect(&:searchable)
  end
end
