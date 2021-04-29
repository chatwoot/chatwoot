json.array! @campaigns do |campaign|
  json.partial! 'api/v1/models/campaign.json.jbuilder', resource: campaign
end
