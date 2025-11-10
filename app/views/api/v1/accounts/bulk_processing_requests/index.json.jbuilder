json.array! @bulk_processing_requests do |bulk_request|
  json.id bulk_request.id
  json.status bulk_request.status
  json.entity_type bulk_request.entity_type
  json.file_name bulk_request.file_name
  json.total_records bulk_request.total_records
  json.processed_records bulk_request.processed_records
  json.failed_records bulk_request.failed_records
  json.progress bulk_request.progress&.to_f
  json.error_message bulk_request.error_message
  json.error_details bulk_request.error_details
  json.job_id bulk_request.job_id
  json.created_at bulk_request.created_at
  json.updated_at bulk_request.updated_at
  json.dismissed_at bulk_request.dismissed_at

  json.user do
    json.id bulk_request.user.id
    json.name bulk_request.user.name
  end
end
