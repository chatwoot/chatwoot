json.id automation_rule.id
json.account_id automation_rule.account_id
json.name automation_rule.name
json.description automation_rule.description
json.event_name automation_rule.event_name
json.conditions automation_rule.conditions
json.actions automation_rule.actions
json.created_on automation_rule.created_at.to_i
json.active automation_rule.active?
json.trigger_count automation_rule.trigger_count
json.files automation_rule.file_base_data if automation_rule.files.any?
json.delay automation_rule.delay
json.delay_type automation_rule.delay_type
