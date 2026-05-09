account_user = Current.account.account_users.find_by(user_id: resource.id) if Current.account
metrics ||= {}

json.id resource.id
json.name resource.name
json.username resource.username
json.phone_number resource.phone_number
json.role account_user&.role
json.job_title account_user&.job_title
json.employee_notes account_user&.employee_notes
json.active account_user&.active
json.availability_status account_user&.availability_status
json.archived_at account_user&.archived_at
json.deactivation_reason account_user&.deactivation_reason
json.confirmed resource.confirmed?
json.locked resource.locked_for_local_auth?
json.failed_login_attempts resource.failed_login_attempts
json.last_sign_in_at resource.last_sign_in_at
json.current_sign_in_at resource.current_sign_in_at
json.last_sign_in_ip resource.last_sign_in_ip
json.current_sign_in_ip resource.current_sign_in_ip
json.last_activity_at metrics[:last_activity_at] || account_user&.active_at
json.open_sessions_count resource.employee_sessions.open.count
json.metrics do
  json.account_status metrics[:account_status]
  json.presence_status metrics[:presence_status]
  json.work_status metrics[:work_status]
  json.last_seen_at metrics[:last_seen_at]
  json.last_activity_at metrics[:last_activity_at]
  json.last_reply_at metrics[:last_reply_at]
  json.time_since_last_reply metrics[:time_since_last_reply]
  json.idle_duration metrics[:idle_duration]
  json.assigned_conversations_count metrics[:assigned_conversations_count].to_i
  json.open_conversations_count metrics[:open_conversations_count].to_i
  json.unreplied_conversations_count metrics[:unreplied_conversations_count].to_i
  json.delayed_unreplied_conversations_count metrics[:delayed_unreplied_conversations_count].to_i
  json.oldest_waiting_customer_at metrics[:oldest_waiting_customer_at]
  json.oldest_waiting_customer_seconds metrics[:oldest_waiting_customer_seconds]
  json.replies_count_today metrics[:replies_count_today].to_i
  json.resolved_conversations_today metrics[:resolved_conversations_today].to_i
  json.first_response_average_today metrics[:first_response_average_today].to_f
  json.average_response_time_today metrics[:average_response_time_today].to_f
  json.average_resolution_time_today metrics[:average_resolution_time_today].to_f
end
json.teams do
  json.array! resource.teams.where(account_id: Current.account.id) do |team|
    json.id team.id
    json.name team.name
  end
end
json.team_ids resource.teams.where(account_id: Current.account.id).pluck(:id)
