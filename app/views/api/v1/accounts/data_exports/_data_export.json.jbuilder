json.extract! data_export, :id, :name, :data_type, :status, :processed_records, :total_records, :export_options,
              :error_message, :created_at, :updated_at, :started_at, :completed_at, :artifacts_expired_at
json.initiated_by data_export.initiated_by&.slice(:id, :name, :email)
json.stalled data_export.stalled?
json.downloadable data_export.downloadable?
json.can_rerun data_export.completed? || data_export.failed? || data_export.stalled?
