json.array! @users do |user|
  json.partial! 'api/v1/models/user', resource: user
end
