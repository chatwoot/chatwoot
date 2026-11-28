namespace :search do
  desc 'Create the conversation search index before enabling advanced_search_conversations'
  task setup_conversations: :environment do
    raise 'Configure OpenSearch before setting up conversation search' unless ChatwootApp.advanced_search_allowed?

    SearchIndexing::Conversations.setup!
    puts "Conversation index: #{Conversation.search_index.name}"
  end
end
