json.array! @employee_sessions do |employee_session|
  json.partial! 'api/v1/models/employee_session', formats: [:json], employee_session: employee_session
end
