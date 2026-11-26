namespace :search do
  desc 'Create the conversation search index'
  task setup_conversations: :environment do
    raise 'Configure OpenSearch before setting up conversation search' unless ChatwootApp.advanced_search_allowed?

    SearchIndexing::Conversations.setup!
    puts "Conversation index: #{Conversation.search_index.name}"
  end

  desc 'Queue conversation reindexing for one account: rake search:reindex_conversations ACCOUNT_ID=123'
  task reindex_conversations: :environment do
    account_id = ENV.fetch('ACCOUNT_ID')
    SearchIndexing::Conversations.reindex_account(account_id)
    puts "Conversation reindex jobs queued for account #{account_id}"
  end
end
