class SearchIndexing::IndexState < ApplicationRecord
  self.table_name = 'search_index_states'

  belongs_to :account, optional: true
  validates :account_id, :entity, :epoch, :schema_version, :run_token, presence: true
  validates :entity, inclusion: { in: SearchIndexing::Registry::DOCUMENTS.keys }
  validates :status, inclusion: { in: %w[running paused ready failed stale purged] }
  validates :phase, inclusion: { in: %w[scan verify_source verify_index drain] }

  def self.invalidate_index!(entity, epoch)
    # An empty replacement affects every tenant; invalidate readiness in one statement before creating it.
    attributes = { status: 'stale', ready_at: nil, run_token: SecureRandom.hex(16), updated_at: Time.current }
    where(entity: entity, epoch: epoch).where.not(ready_at: nil).update_all(attributes) # rubocop:disable Rails/SkipsModelValidations
  end

  def self.purge_for(account_id)
    buffer = SearchIndexing::Buffer.new(entity: 'conversations', account_id: account_id)
    state = find_by(account_id: account_id, entity: 'conversations')
    return unless state || buffer.used?

    state ||= new(account_id: account_id, entity: 'conversations')
    state.update!(epoch: buffer.epoch, schema_version: SearchIndexing::ConversationDocument::SCHEMA_VERSION,
                  status: 'running', phase: 'verify_index', cursor: 0, ready_at: nil, last_error: nil, run_token: SecureRandom.hex(16))
    SearchIndexing::BackfillJob.perform_later(state.id, state.run_token)
    state
  end

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
      schema_version == SearchIndexing::Registry.fetch(entity)::SCHEMA_VERSION && buffer.statistics[:failed].zero?
  end
end
