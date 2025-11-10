json.id @bulk_processing_request.id
json.status @bulk_processing_request.status
json.entity_type @bulk_processing_request.entity_type
json.file_name @bulk_processing_request.file_name
json.total_records @bulk_processing_request.total_records
json.processed_records @bulk_processing_request.processed_records
json.failed_records @bulk_processing_request.failed_records
json.progress @bulk_processing_request.progress
json.error_message @bulk_processing_request.error_message
json.job_id @bulk_processing_request.job_id
json.created_at @bulk_processing_request.created_at
json.updated_at @bulk_processing_request.updated_at
json.dismissed_at @bulk_processing_request.dismissed_at

json.user do
  json.id @bulk_processing_request.user.id
  json.name @bulk_processing_request.user.name
  json.email @bulk_processing_request.user.email
end
