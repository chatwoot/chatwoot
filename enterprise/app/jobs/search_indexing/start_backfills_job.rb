class SearchIndexing::StartBackfillsJob < ApplicationJob
  queue_as :search_backfill

  def perform(entity, after_account_id = 0)
    SearchIndexing::Registry::DOCUMENTS.fetch(entity)
    accounts = Account.where(id: (after_account_id + 1)..).order(:id).limit(25).to_a
    accounts.each do |account|
      next unless SearchIndexing::Producer.eligible?(entity, account)
      next if SearchIndexing::IndexState.exists?(account_id: account.id, entity: entity, status: 'running')

      SearchIndexing::Backfill.start(account: account, entity: entity)
    end
    self.class.perform_later(entity, accounts.last.id) if accounts.size == 25
  end
end
