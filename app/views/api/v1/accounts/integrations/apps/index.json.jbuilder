json.payload do
  json.array! @apps do |app|
    json.id app.id
    json.name app.name
    json.description app.description
    json.logo app.logo
    json.enabled app.enabled?(@current_account)
    json.action app.action
  end
end
