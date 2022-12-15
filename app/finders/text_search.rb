class TextSearch
  attr_reader :current_user, :current_account, :params

  DEFAULT_STATUS = 'open'.freeze

  def initialize(current_user, params)
    @current_account = current_user.account || Current.account
    @params = params
  end

  def perform
    {
      messages: filter_messages,
      conversations: filter_conversations,
      contacts: filter_contacts
    }
  end

  private

  def filter_conversations
    conversation_ids = PgSearch.multisearch((@params[:q]).to_s).where(account_id: @current_account,
                                                                      searchable_type: 'Conversation').pluck(:searchable_id)
    @conversations = Conversation.where(id: conversation_ids)
  end

  def filter_messages
    message_ids = PgSearch.multisearch((@params[:q]).to_s).where(account_id: @current_account, searchable_type: 'Message').pluck(:searchable_id)
    @messages = Message.where(id: message_ids)
  end

  def filter_contacts
    contact_ids = PgSearch.multisearch((@params[:q]).to_s).where(account_id: @current_account, searchable_type: 'Contact').pluck(:searchable_id)
    @contacts = Contact.where(id: contact_ids)
  end
end
