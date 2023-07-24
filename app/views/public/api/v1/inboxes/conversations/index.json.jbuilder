json.array! @conversations do |conversation|
  json.partial! 'public/api/v1/models/conversation', formats: [:json], resource: conversation
end
