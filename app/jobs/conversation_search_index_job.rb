class ConversationSearchIndexJob < ApplicationJob
  queue_as :async_database_migration

  def perform
    return unless ChatwootApp.advanced_search_allowed?
    # Provisioning is an explicit operator action; keep queued IDs if the index is absent.
    return unless Conversation.search_index.exists?

    Searchkick::ProcessQueueJob.perform_later(class_name: 'Conversation')
  end
end
