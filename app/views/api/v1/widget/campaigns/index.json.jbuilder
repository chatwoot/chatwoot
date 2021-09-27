json.array! @campaigns do |campaign|
  json.id campaign.display_id
  json.trigger_rules campaign.trigger_rules
  json.trigger_only_during_business_hours campaign.trigger_only_during_business_hours
  json.message campaign.message
  json.sender campaign.sender&.slice(:name, :avatar_url)
end
