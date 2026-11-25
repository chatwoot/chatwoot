json.array! @users do |user|
  json.partial! 'api/v1/models/agent', formats: [:json], resource: user
end
