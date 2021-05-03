json.array! @campaigns do |campaign|
  json.id campaign.display_id
  json.trigger_rules campaign.trigger_rules
end
