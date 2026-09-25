# Runs the conversation list's advanced filters against one contact's conversations.
class Contacts::ConversationFilterService < Conversations::FilterService
  def initialize(params, user, account, contact:)
    @contact = contact
    super(params, user, account)
  end

  def base_relation
    super.where(contact_id: @contact.id)
  end
end
