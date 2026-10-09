class Internal::ExpireDataOperationFilesJob < ApplicationJob
  queue_as :housekeeping
  RETENTION = 30.days

  def perform
    DataImport.where(source_provider: 'csv', status: [:completed, :completed_with_errors, :failed, :abandoned])
              .where('COALESCE(completed_at, abandoned_at, last_error_at, updated_at) < ?', RETENTION.ago)
              .where("source_metadata ->> 'artifacts_expired_at' IS NULL").find_each { |record| expire_import(record) }
    DataExport.where(status: [:completed, :failed], artifacts_expired_at: nil)
              .where('completed_at < ?', RETENTION.ago).find_each { |record| expire_export(record) }
  end

  private

  def expire_import(record)
    record.with_lock do
      terminal_at = record.completed_at || record.abandoned_at || record.last_error_at || record.updated_at
      next if record.pending? || record.processing? || terminal_at >= RETENTION.ago

      record.update!(source_metadata: record.source_metadata.merge('artifacts_expired_at' => Time.current.iso8601))
      record.import_file.purge_later
      record.failed_records.purge_later
      # Keep row outcomes and counters, remove the source contact data and diagnostic values.
      record.items.update_all("metadata = metadata - 'fields', last_error_message = NULL") # rubocop:disable Rails/SkipsModelValidations
      record.import_errors.delete_all
    end
  end

  def expire_export(record)
    record.with_lock do
      next unless record.completed? || record.failed?

      record.update!(artifacts_expired_at: Time.current)
      record.export_file.purge_later
    end
  end
end
