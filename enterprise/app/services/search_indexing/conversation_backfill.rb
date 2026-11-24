class SearchIndexing::ConversationBackfill
  def self.start(account_ids: nil, all_enabled_accounts: false, batch_size: SearchIndexing::Conversations::BATCH_SIZE,
                 after_account_id: 0, after_id: 0)
    validate_selection!(account_ids, all_enabled_accounts)
    raise ArgumentError, 'batch_size must be between 1 and 500' unless batch_size.is_a?(Integer) && batch_size.between?(1, 500)

    validate_cursor!(account_ids, after_account_id, after_id)
    raise 'Configure OpenSearch before backfilling' unless ChatwootApp.advanced_search_allowed?

    index_identity = SearchIndexing::IndexVerification.identity
    SearchIndexing::ConversationBackfillJob.perform_later(
      account_ids: account_ids, cursor: { after_account_id: after_account_id, after_id: after_id, account_upper_id: Account.maximum(:id) || 0 },
      batch_size: batch_size, index_identity: index_identity
    )
  end

  def self.validate_selection!(account_ids, all_enabled_accounts)
    if all_enabled_accounts
      raise ArgumentError, 'Do not supply account_ids with all_enabled_accounts' unless account_ids.nil?

      return
    end
    raise ArgumentError, 'Select at least one account' if account_ids.blank?

    validate_account_ids!(account_ids)
  end

  def self.validate_account_ids!(account_ids)
    valid_ids = account_ids.is_a?(Array) && account_ids.all? { |id| id.is_a?(Integer) && id.positive? }
    return if valid_ids

    raise ArgumentError, 'account_ids must contain positive integers'
  end

  def self.validate_cursor!(account_ids, after_account_id, after_id)
    raise ArgumentError, 'Cursors must be non-negative integers' unless [after_account_id, after_id].all? { |id| id.is_a?(Integer) && id >= 0 }
    raise ArgumentError, 'Resume a single account when supplying after_id' if after_id.positive? && account_ids&.size != 1
  end
  private_class_method :validate_selection!, :validate_account_ids!, :validate_cursor!

  def self.verify(account_id:, activate: false)
    SearchIndexing::ConversationVerification.new(Account.find(account_id)).perform(activate: activate)
  end
end
