json.id resource.id
json.account_id resource.account_id
json.short_code resource.short_code
json.content resource.content
json.created_at resource.created_at
json.updated_at resource.updated_at
if resource.canned_attachments.reload.present?
  json.attachments resource.canned_attachments.reload.map {|a| {blob: a.file_blob, signed_id: a.file_blob.signed_id}.merge(**a.push_event_data) }
end
