json.array! @documents do |document|
  json.partial! 'api/v1/models/captain/document', formats: [:json], resource: document
end
