class Internal::ExpireDataOperationFilesJob < ApplicationJob
  queue_as :housekeeping
  RETENTION = 30.days

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
    DataImport.where(source_provider: 'csv').or(DataImport.where(data_type: 'contacts', source_provider: [nil, '']))
              .where(status: [:completed, :completed_with_errors, :failed, :abandoned])
              .where(terminal_at.lt(RETENTION.ago)).where(expired_at.eq(nil))
  end

  def expire_import(record)
    record.with_lock do
      terminal_at = record.completed_at || record.abandoned_at || record.last_error_at || record.updated_at
      next if record.pending? || record.processing? || terminal_at >= RETENTION.ago

      record.update!(source_metadata: record.source_metadata.merge('artifacts_expired_at' => Time.current.iso8601))
      record.import_file.purge_later
      record.failed_records.purge_later
      scrub_staged_rows(record)
    end
  end

  def scrub_staged_rows(record)
    # Keep row outcomes and counters, remove the source contact data and diagnostic values.
    metadata = Arel::Nodes::InfixOperation.new('-', DataImportItem.arel_table[:metadata], Arel::Nodes.build_quoted('fields'))
    record.items.update_all(metadata: metadata, last_error_message: nil) # rubocop:disable Rails/SkipsModelValidations
    DataImportError.where(data_import_id: record.id).delete_all
  end

  def expire_export(record)
    record.with_lock do
      next unless record.completed? || record.failed?

      record.update!(artifacts_expired_at: Time.current)
      record.export_file.purge_later
    end
  end
end
