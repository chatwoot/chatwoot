class BackfillCaptainDocumentSyncMetadata < ActiveRecord::Migration[7.0]
  def up
    return unless ChatwootApp.enterprise?

    # rubocop:disable Rails/SkipsModelValidations
    Captain::Document
      .syncable
      .where(status: :available, sync_status: nil, last_synced_at: nil)
      .in_batches(of: 1000) do |batch|
        batch.update_all('sync_status = 1, last_synced_at = updated_at')
      end
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    # No-op. This is a one-time baseline for existing available web documents.
  end
end
