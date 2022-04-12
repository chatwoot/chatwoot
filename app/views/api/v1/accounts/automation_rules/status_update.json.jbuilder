json.payload do
  json.partial! 'api/v1/accounts/automation_rules/partials/automation_rule.json.jbuilder', automation_rule: @automation_rule
end
