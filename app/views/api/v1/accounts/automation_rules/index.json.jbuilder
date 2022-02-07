json.payload do
  json.array! @automation_rules do |automation_rule|
    json.partial! 'api/v1/accounts/automation_rules/partials/automation_rule.json.jbuilder', automation_rule: automation_rule
  end
end
