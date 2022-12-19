class Conversations::MultiSearchJob < ApplicationJob
  queue_as :default

  def perform
    Contact.rebuild_pg_search_documents
    PgSearch::Multisearch.rebuild(Conversation)
    PgSearch::Multisearch.rebuild(Message)
  end
end
