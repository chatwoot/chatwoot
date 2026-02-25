json.data do
  json.partial! 'api/v1/models/inbox', formats: [:json], resource: @inbox
end
