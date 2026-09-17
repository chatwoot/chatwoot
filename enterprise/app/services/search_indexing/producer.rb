module SearchIndexing::Producer
  def self.eligible?(entity, account)
    return false unless ChatwootApp.advanced_search_allowed? && account
    return false unless account.feature_enabled?(SearchIndexing::Registry.fetch(entity)::INDEXING_FEATURE)

    !ChatwootApp.chatwoot_cloud? || account.feature_enabled?('advanced_search_indexing')
  end

  def self.enqueue(entity:, account_id:, ids:, cleanup: false)
    return unless ChatwootApp.advanced_search_allowed?

    ActiveRecord.after_all_transactions_commit do
      account = Account.find_by(id: account_id)
      next unless cleanup || eligible?(entity, account)

      SearchIndexing::Buffer.new(entity: entity, account_id: account_id).enqueue(ids)
    end
  end
end
