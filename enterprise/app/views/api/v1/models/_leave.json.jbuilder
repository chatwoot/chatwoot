json.id leave.id
json.start_date leave.start_date
json.end_date leave.end_date
json.leave_type leave.leave_type
json.status leave.status
json.reason leave.reason
json.duration_in_days leave.duration_in_days
json.approved_at leave.approved_at&.to_i
json.created_at leave.created_at.to_i
json.updated_at leave.updated_at.to_i

json.user do
  json.id leave.user.id
  json.name leave.user.name
  json.email leave.user.email
end

if leave.approver.present?
  json.approver do
    json.id leave.approver.id
    json.name leave.approver.name
    json.email leave.approver.email
  end
else
  json.approver nil
end
