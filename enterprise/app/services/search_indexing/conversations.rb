module SearchIndexing::Conversations
  BATCH_SIZE = 500

  def self.enabled?(account)
    ChatwootApp.advanced_search_allowed? && account&.feature_enabled?('advanced_search_conversations')
  end

  def self.enqueue(account_id, ids, cleanup: false)
    return unless ChatwootApp.advanced_search_allowed?

    ActiveRecord.after_all_transactions_commit do
      account = Account.find_by(id: account_id)
      next unless cleanup || enabled?(account)

      Conversation.search_index.reindex_queue.push(ids)
    rescue Redis::BaseError, ConnectionPool::TimeoutError => e
      # The primary write has committed; an optional index update must not interrupt its remaining callbacks.
      ChatwootExceptionTracker.new(e, account: account).capture_exception
    end
  end

  def self.setup!
    index = Conversation.search_index
    if index.exists?
      Searchkick.client.indices.put_mapping(index: index.name, body: SearchIndexing::ConversationDocument.mappings)
    else
      index.create(index.index_options)
    end
  end

  def self.reindex_account(account_id)
    account = Account.find(account_id)
    raise ArgumentError, 'Configure OpenSearch and enable advanced_search_conversations before reindexing' unless enabled?(account)
    raise Searchkick::Error, 'Run search:setup_conversations before reindexing' unless Conversation.search_index.exists?

    account.conversations.reindex(mode: :async)
  end
end
