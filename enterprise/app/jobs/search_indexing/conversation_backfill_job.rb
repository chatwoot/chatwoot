class SearchIndexing::ConversationBackfillJob < ApplicationJob
  queue_as :async_database_migration

  def perform(account_ids:, index_identity:, batch_size: 500, cursor: {})
    return unless ChatwootApp.advanced_search_allowed?
    raise 'Conversation index changed; restart the backfill' unless SearchIndexing::IndexVerification.identity == index_identity

    @cursor = { after_account_id: 0, after_id: 0, account_upper_id: Account.maximum(:id) || 0 }.merge(cursor.symbolize_keys)
    @account = find_account(account_ids)
    return unless SearchIndexing::Conversations.enabled?(@account)

    ids = import_page(batch_size, index_identity.fetch('name'))
    self.class.perform_later(account_ids: account_ids, index_identity: index_identity, batch_size: batch_size, cursor: next_cursor(ids, batch_size))
  end

  private

  def import_page(batch_size, index_name)
    @cursor[:upper_id] ||= @account.conversations.maximum(:id) || 0
    ids = @account.conversations.where(id: (@cursor[:after_id] + 1)..@cursor[:upper_id]).order(:id).limit(batch_size).pluck(:id)
    Searchkick::ProcessBatchJob.perform_now(class_name: 'Conversation', record_ids: ids.map(&:to_s), index_name: index_name) if ids.any?
    ids
  end

  def find_account(account_ids)
    return Account.find_by(id: @cursor[:account_id]) if @cursor[:account_id]

    accounts = Account.feature_advanced_search_conversations.where(id: (@cursor[:after_account_id] + 1)..@cursor.fetch(:account_upper_id))
    accounts = accounts.where(id: account_ids) if account_ids
    accounts.order(:id).first
  end

  def next_cursor(ids, batch_size)
    Rails.logger.info("Conversation backfill account=#{@account.id} after_id=#{ids.last || @cursor[:after_id]} upper_id=#{@cursor[:upper_id]}")
    return @cursor.merge(account_id: @account.id, after_id: ids.last) if ids.size == batch_size

    Rails.logger.info("Conversation backfill scan completed account=#{@account.id}; verification required")
    { after_account_id: @account.id, after_id: 0, account_upper_id: @cursor.fetch(:account_upper_id) }
  end
end
