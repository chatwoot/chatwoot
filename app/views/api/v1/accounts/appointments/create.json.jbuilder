json.id @appointment.id
json.location @appointment.location
json.description @appointment.description
json.start_time @appointment.start_time
json.end_time @appointment.end_time
json.contact_id @appointment.contact_id
json.created_at @appointment.created_at
json.updated_at @appointment.updated_at
json.qr_code_url show_qr_api_v1_account_appointment_url(@appointment.account.id, @appointment.id)
