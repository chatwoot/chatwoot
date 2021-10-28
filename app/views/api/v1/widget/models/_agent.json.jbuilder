json.id resource.id
json.name resource.available_name
json.avatar_url resource.avatar_url
json.availability_status resource.account_users.find_by(account_id: @current_account.id).availability_status