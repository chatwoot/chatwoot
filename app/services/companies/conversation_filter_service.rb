# Runs the conversation list's advanced filters against one company's conversations.
class Companies::ConversationFilterService < Conversations::FilterService
  def initialize(params, user, account, company:)
    @company = company
    super(params, user, account)
  end

  def base_relation
    super.where(contact_id: @company.contacts.select(:id))
  end
end
