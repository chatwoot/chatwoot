json.id automation_rule.id
json.account_id automation_rule.account_id
json.name automation_rule.name
json.description automation_rule.description
json.event_name automation_rule.event_name
json.conditions automation_rule.conditions
json.actions automation_rule.actions
json.created_on automation_rule.created_at.to_i
json.active automation_rule.active?
json.files automation_rule.file_base_data if automation_rule.files.any?
