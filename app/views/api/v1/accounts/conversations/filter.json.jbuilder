json.meta do
  json.mine_count @conversations_count[:mine_count]
  json.unassigned_count @conversations_count[:unassigned_count]
  json.all_count @conversations_count[:all_count]
  json.all_inbox_open_count @conversations_count[:all_inbox_open_count]
  json.my_teams_open_count @conversations_count[:my_teams_open_count]
end
json.payload do
  json.array! @conversations do |conversation|
    json.partial! 'api/v1/conversations/partials/conversation', formats: [:json], conversation: conversation
  end
end
