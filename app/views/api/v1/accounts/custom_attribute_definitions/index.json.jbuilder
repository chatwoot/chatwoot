json.array! @custom_attribute_definitions do |custom_attribute_definition|
  json.partial! 'api/v1/models/custom_attribute_definition', formats: [:json], resource: custom_attribute_definition
end
