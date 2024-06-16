# views/api/v2/accounts/permissions/show.jbuilder

json.id @user.id
json.email @user.email
json.permissions @user.permissions
