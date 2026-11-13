class Internal::ExpireDataOperationFilesJob < ApplicationJob
  queue_as :housekeeping
  RETENTION = 30.days
  CLEANUP_BATCH_SIZE = 1000

  def perform
    imports_to_expire.find_each { |record| expire_import(record) }
    DataExport.where(status: [:completed, :failed], artifacts_expired_at: nil, completed_at: ...RETENTION.ago)
              .find_each { |record| expire_export(record) }
  end

  private

  def imports_to_expire
    imports = DataImport.arel_table
    terminal_at = Arel::Nodes::NamedFunction.new('COALESCE', %i[completed_at abandoned_at last_error_at updated_at].map { |column| imports[column] })
    expired_at = Arel::Nodes::InfixOperation.new('->>', imports[:source_metadata], Arel::Nodes.build_quoted('artifacts_expired_at'))
    cleanup_pending = Arel::Nodes::InfixOperation.new('->>', imports[:source_metadata], Arel::Nodes.build_quoted('artifacts_cleanup_pending'))
    DataImport.where(source_provider: 'csv').or(DataImport.where(data_type: 'contacts', source_provider: [nil, '']))
              .where(status: [:completed, :completed_with_errors, :failed, :abandoned])
              .where(terminal_at.lt(RETENTION.ago).and(expired_at.eq(nil)).or(cleanup_pending.eq('true')))
  end

  def expire_import(record)
    record.with_lock do
      return unless import_expirable?(record)

      # Block restarts before releasing the lock, and keep interrupted cleanup eligible for retry.
      record.update!(source_metadata: record.source_metadata.merge(
        'artifacts_expired_at' => record.source_metadata['artifacts_expired_at'] || Time.current.iso8601,
        'artifacts_cleanup_pending' => true
      ))
      record.import_file.purge_later
      record.failed_records.purge_later
    end
    scrub_staged_rows(record)
    record.with_lock { record.update!(source_metadata: record.source_metadata.except('artifacts_cleanup_pending')) }
  end

  def import_expirable?(record)
    return false if record.status.in?(%w[pending processing])
    return true if record.source_metadata['artifacts_cleanup_pending']

    terminal_at = record.completed_at || record.abandoned_at || record.last_error_at || record.updated_at
    record.source_metadata['artifacts_expired_at'].blank? && terminal_at < RETENTION.ago
  end

  def scrub_staged_rows(record)
    # Keep row outcomes and counters, remove the source contact data and diagnostic values.
    metadata = Arel::Nodes::InfixOperation.new('-', DataImportItem.arel_table[:metadata], Arel::Nodes.build_quoted('fields'))
    record.items.in_batches(of: CLEANUP_BATCH_SIZE) do |batch|
      batch.update_all(metadata: metadata, last_error_message: nil) # rubocop:disable Rails/SkipsModelValidations
    end
    record.import_errors.in_batches(of: CLEANUP_BATCH_SIZE).delete_all
  end

  def expire_export(record)
    record.with_lock do
      next unless record.completed? || record.failed?

      record.update!(artifacts_expired_at: Time.current)
      record.export_file.purge_later
    end
  end
end
