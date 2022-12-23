class Conversations::AccountBasedSearchJob < ApplicationJob
  queue_as :default

  def perform(account_id)
    Contact.rebuild_pg_search_documents(account_id)
    Conversation.rebuild_pg_search_documents(account_id)
    Message.rebuild_pg_search_documents(account_id)
  end
end
