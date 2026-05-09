json.partial! 'api/v1/models/employee', formats: [:json], resource: @employee, metrics: @employee_metrics&.dig(@employee.id)
