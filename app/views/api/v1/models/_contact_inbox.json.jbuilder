json.source_id resource.source_id
whatsapp_identity = Whatsapp::IdentityPresenter.new(resource).identity
json.whatsapp_identity whatsapp_identity if whatsapp_identity.present?
json.inbox do
  json.partial! 'api/v1/models/inbox_slim', formats: [:json], resource: resource.inbox
end
