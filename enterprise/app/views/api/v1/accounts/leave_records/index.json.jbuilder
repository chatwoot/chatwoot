json.array! @leave_records do |leave_record|
  json.partial! 'api/v1/models/leave_record', formats: [:json], leave_record: leave_record
end
