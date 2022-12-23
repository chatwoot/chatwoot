class Conversations::AccountBasedSearchJob < ApplicationJob
  queue_as :default

  def perform
    Contact.rebuild_pg_search_documents(account.id)
    Conversation.rebuild_pg_search_documents(account.id)
    Message.rebuild_pg_search_documents(account.id)
  end
end
