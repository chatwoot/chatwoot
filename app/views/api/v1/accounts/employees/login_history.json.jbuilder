json.array! @login_events do |employee_login_event|
  json.partial! 'api/v1/models/employee_login_event', formats: [:json], employee_login_event: employee_login_event
end
