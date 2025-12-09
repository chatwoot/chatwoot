json.array! @funnels do |funnel|
  json.partial! 'api/v1/models/funnel', formats: [:json], resource: funnel
end

