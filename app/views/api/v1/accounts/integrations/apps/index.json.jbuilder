json.array! @apps do |app|
  json.id app.id
  json.name app.name
  json.logo app.logo
end
