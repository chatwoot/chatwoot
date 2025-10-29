json.per_page @per_page
json.total_entries @total_entries
json.current_page @current_page

json.audit_logs do
  json.array! @audit_logs do |audit_log|
    json.id audit_log.id
    json.auditable_id audit_log.auditable_id
    json.auditable_type audit_log.auditable_type
    json.auditable audit_log.auditable.try(:push_event_data)
    json.associated_id audit_log.associated_id
    json.associated_type audit_log.associated_type
    json.user_id   audit_log.user_id
    json.user_type audit_log.user_type
    json.username audit_log.username
    json.action audit_log.action
    json.audited_changes audit_log.audited_changes
    json.version audit_log.version
    json.comment audit_log.comment
    json.request_uuid audit_log.request_uuid
    json.created_at audit_log.created_at.to_i
    json.remote_address audit_log.remote_address
  end
end
