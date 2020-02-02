json.payload do
  json.array! @inbox_members do |inbox_member|
    json.name inbox_member.user.name
    json.avatar_url inbox_member.user.avatar_url
    json.availability_status inbox_member.user.availability_status
  end
end
