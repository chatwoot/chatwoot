json.array! @campaigns do |campaign|
  json.id campaign.display_id
  json.trigger_rules campaign.trigger_rules
  json.message campaign.message
  json.sender campaign.sender&.slice(:name, :avatar_url)
end
