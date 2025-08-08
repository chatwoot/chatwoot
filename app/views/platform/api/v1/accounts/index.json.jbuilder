json.array! @resources do |account|
  json.partial! 'platform/api/v1/models/account', formats: [:json], resource: account
end
