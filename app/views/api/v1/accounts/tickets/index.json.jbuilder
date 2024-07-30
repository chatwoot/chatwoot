json.payload do
  json.array! @tickets do |ticket|
    json.partial! 'api/v1/models/ticket', formats: [:json], resource: ticket
  end
end
