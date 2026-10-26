json.auth_type @result.auth_type
json.name @result.name
json.version @result.version
json.tools @result.tools do |tool|
  json.name tool['name']
  json.description tool['description']
  json.input_schema tool['input_schema']
  json.read_only tool['read_only']
end
