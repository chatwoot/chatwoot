json.inboxes @inboxes do |inbox|
  json.partial! 'api/v1/models/inbox', formats: [:json], resource: inbox
end
