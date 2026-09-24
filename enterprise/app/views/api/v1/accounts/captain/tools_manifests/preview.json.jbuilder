json.name @manifest['name']
json.description @manifest['description']
json.version @manifest['version']
json.repository @github_source.repository
json.path @github_source.path
json.revision @revision
json.installed_revision @installed_revision
json.up_to_date @up_to_date
fields = %w[inputs secrets].flat_map { |section| @manifest[section].map { |name, definition| [section, name, definition] } }
json.fields fields do |(section, name, definition)|
  json.name name
  json.section section
  json.label definition['label']
  json.type definition['type']
  json.placeholder definition['placeholder']
  json.required definition['required']
  json.options definition['options']
end
json.tools @manifest['tools'] do |tool|
  json.id tool['id']
  json.title tool['title']
  json.description tool['description']
  json.http_method tool['http_method']
end
