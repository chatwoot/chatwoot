json.id canned_response.id
json.account_id canned_response.account_id
json.short_code canned_response.short_code
json.content canned_response.content
json.created_at canned_response.created_at
json.updated_at canned_response.updated_at
json.files canned_response.files do |file|
  json.signed_id file.signed_id
  json.filename file.filename.to_s
  json.content_type file.content_type
  json.byte_size file.byte_size
  json.file_url rails_blob_url(file)
end
