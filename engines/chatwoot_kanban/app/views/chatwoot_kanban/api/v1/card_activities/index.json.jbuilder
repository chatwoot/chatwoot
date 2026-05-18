json.data do
  json.array! @activities do |activity|
    json.id activity.id
    json.card_id activity.card_id
    json.actor_id activity.actor_id
    json.action activity.action
    json.payload activity.payload
    json.created_at activity.created_at.iso8601
  end
end
