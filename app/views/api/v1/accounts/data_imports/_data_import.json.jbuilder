json.id data_import.id
json.name data_import.name
json.data_type data_import.data_type
json.source_type data_import.source_type
json.source_provider data_import.source_provider
json.import_types data_import.import_types
json.status data_import.status
json.stalled data_import.stalled?
json.total_records data_import.total_records
json.processed_records data_import.processed_records
json.stats data_import.stats
json.cursor data_import.cursor
json.created_at data_import.created_at
json.updated_at data_import.updated_at
json.started_at data_import.started_at
json.completed_at data_import.completed_at
json.abandoned_at data_import.abandoned_at
json.initiated_by data_import.initiated_by&.slice(:id, :name, :email)
json.file_name data_import.import_file.filename.to_s if data_import.import_file.attached?
json.rejected_rows_available data_import.failed_records.attached?
json.artifacts_expired_at data_import.source_metadata['artifacts_expired_at'] if data_import.csv_import?
json.allowed_actions do
  json.abandon data_import.abandonable?
  json.retry data_import.stalled? && data_import.source_available?
  json.start data_import.managed_import? && data_import.restartable? && data_import.source_available?
end
if @import_errors_counts
  json.import_errors_count @import_errors_counts.fetch(data_import.id, 0)
  json.skip_logs_count (@skip_logs_counts || {}).fetch(data_import.id, 0)
else
  json.import_errors_count data_import.import_errors.non_skip_logs.count
  json.skip_logs_count data_import.import_errors.skip_logs.count
end
