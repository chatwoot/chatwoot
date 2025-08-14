json.message I18n.t('agent_capacity.user_unassigned')
json.user do
  json.id @user.id
  json.name @user.name
  json.email @user.email
end