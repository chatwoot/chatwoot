json.id account_user.id
json.role account_user.role
json.availability account_user.availability
json.auto_offline account_user.auto_offline
json.permissions account_user.permissions_without_defaults

json.user do
  json.partial! 'api/v1/models/user', resource: account_user.user
end
