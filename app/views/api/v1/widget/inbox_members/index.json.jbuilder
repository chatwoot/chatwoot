json.payload do
  json.array! @inbox_members do |inbox_member|
    json.partial! 'api/v1/widget/models/agent.json.jbuilder', resource: inbox_member.user
  end
end
