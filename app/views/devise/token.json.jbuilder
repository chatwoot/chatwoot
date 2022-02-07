json.payload do
  json.success true
  json.partial! 'auth.json.jbuilder', resource: @resource
  json.data do
    json.created_at @resource.created_at
  end
end
