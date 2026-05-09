json.array! @employees do |employee|
  json.partial! 'api/v1/models/employee', formats: [:json], resource: employee, metrics: @employee_metrics[employee.id]
end
