json.array! @campaigns do |campaign|
  json.partial! 'api/v1/models/campaign', formats: [:json], resource: campaign
end
