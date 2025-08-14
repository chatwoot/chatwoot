json.inboxes @inboxes do |inbox|
  json.partial! 'api/v1/models/inbox', formats: [:json], locals: { resource: inbox }
end