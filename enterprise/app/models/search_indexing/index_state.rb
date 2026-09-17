class SearchIndexing::IndexState < ApplicationRecord
  self.table_name = 'search_index_states'

  belongs_to :account, optional: true
  validates :account_id, :entity, :epoch, :schema_version, :run_token, presence: true
  validates :entity, inclusion: { in: SearchIndexing::Registry::DOCUMENTS.keys }
  validates :status, inclusion: { in: %w[running paused ready failed stale purged] }
  validates :phase, inclusion: { in: %w[scan verify_source verify_index drain] }

  def document
    SearchIndexing::Registry.fetch(entity).new(account_id)
  end

  def buffer
    SearchIndexing::Buffer.new(entity: entity, account_id: account_id, epoch: epoch)
  end

  def invalidate!
    update!(status: 'stale', ready_at: nil, run_token: SecureRandom.hex(16))
  end

  def pause!
    with_lock { update!(status: 'paused', run_token: SecureRandom.hex(16)) }
  end

  def resume!
    with_lock do
      raise SearchIndexing::StaleGenerationError, 'Restart the backfill for the current generation' unless epoch == SearchIndexing::Store.epoch

      update!(status: 'running', last_error: nil, run_token: SecureRandom.hex(16))
    end
    SearchIndexing::BackfillJob.perform_later(id, run_token)
  end

  def readable?
    ready_at.present? && status.in?(%w[ready running]) && epoch == SearchIndexing::Store.epoch &&
      schema_version == SearchIndexing::Registry.fetch(entity)::SCHEMA_VERSION
  end
end
