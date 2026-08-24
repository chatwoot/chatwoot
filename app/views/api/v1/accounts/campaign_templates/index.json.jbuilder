json.array! @campaign_templates do |campaign_template|
  json.partial! 'api/v1/models/campaign_template', formats: [:json], resource: campaign_template
end
