# views/api/v2/accounts/permissions/show.jbuilder
json.data do
  json.id @account_user.id
  json.name @account_user.user.name
  json.permissions @account_user.permissions
end
