json.id leave_record.id
json.start_date leave_record.start_date
json.end_date leave_record.end_date
json.leave_type leave_record.leave_type
json.status leave_record.status
json.reason leave_record.reason
json.duration_in_days leave_record.duration_in_days
json.approved_at leave_record.approved_at&.to_i
json.created_at leave_record.created_at.to_i
json.updated_at leave_record.updated_at.to_i

json.user do
  json.id leave_record.user.id
  json.name leave_record.user.name
  json.email leave_record.user.email
end

if leave_record.approver.present?
  json.approver do
    json.id leave_record.approver.id
    json.name leave_record.approver.name
    json.email leave_record.approver.email
  end
else
  json.approver nil
end
