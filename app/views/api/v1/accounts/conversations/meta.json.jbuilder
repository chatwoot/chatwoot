json.meta do
  json.mine_count @conversations_count[:mine_count]
  json.assigned_count @conversations_count[:assigned_count]
  json.unassigned_count @conversations_count[:unassigned_count]
  json.all_count @conversations_count[:all_count]
  json.all_inbox_open_count @conversations_count[:all_inbox_open_count]
  json.my_teams_open_count @conversations_count[:my_teams_open_count]
end
