json.payload do
  json.success true
  json.partial! 'auth.json.jbuilder', resource: @resource
end
