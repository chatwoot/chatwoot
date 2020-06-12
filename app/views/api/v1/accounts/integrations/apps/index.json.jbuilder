json.array! @apps do |app|
  json.id app.id
  json.name app.name
  json.logo app.logo
  json.enabled app.enabled?(@current_account)
  json.button app.button
end
