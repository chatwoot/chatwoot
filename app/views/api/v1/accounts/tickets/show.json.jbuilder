json.partial! 'api/v1/models/ticket', formats: [:json], resource: @ticket

json.labels @ticket.labels.map do |label|
  json.partial! 'api/v1/models/label', label: label
end
