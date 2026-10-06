json.array! @installed_toolsets do |(repository, path, version)|
  json.repository repository
  json.path path
  json.version version
end
