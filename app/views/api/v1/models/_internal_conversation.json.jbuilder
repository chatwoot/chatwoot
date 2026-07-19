json.id resource.id
json.account_id resource.account_id
json.team_id resource.team_id
json.last_activity_at resource.last_activity_at&.to_i
json.last_message_preview resource.last_message_preview
json.created_at resource.created_at.to_i
json.updated_at resource.updated_at.to_i

if resource.team.present?
  json.team do
    json.id resource.team.id
    json.name resource.team.name
    json.members resource.team.members do |member|
      json.id member.id
      json.name member.available_name.presence || member.name
      json.thumbnail member.avatar_url
      json.availability_status member.availability_status
    end
  end
end
