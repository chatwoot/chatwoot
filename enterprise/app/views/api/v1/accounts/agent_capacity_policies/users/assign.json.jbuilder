json.message I18n.t('agent_capacity.user_assigned')
json.user do
  json.id @user.id
  json.name @user.name
  json.email @user.email
end
json.agent_capacity_policy do
  json.id @agent_capacity_policy.id
  json.name @agent_capacity_policy.name
end