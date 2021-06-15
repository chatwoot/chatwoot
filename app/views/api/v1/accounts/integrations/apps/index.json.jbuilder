json.payload do
  json.array! @apps do |app|
    json.partial! 'api/v1/models/app.json.jbuilder', resource: app
  end
end
