json.id resource.id
json.name resource.name
json.description resource.description
json.allow_auto_assign resource.allow_auto_assign
json.account_id resource.account_id
json.slack_mention_code resource.slack_mention_code
json.is_member Current.user.teams.include?(resource)
