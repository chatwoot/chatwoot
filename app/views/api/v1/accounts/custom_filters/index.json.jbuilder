json.array! @custom_filters do |custom_filter|
  json.partial! 'api/v1/models/custom_filter.json.jbuilder', resource: custom_filter
end
