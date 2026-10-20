json.array! @sessions do |session|
  json.id session.id
  json.browser_name session.browser_name
  json.browser_version session.browser_version
  json.device_name session.device_name
  json.platform_name session.platform_name
  json.platform_version session.platform_version
  json.ip_address session.ip_address
  json.city session.city
  json.country session.country
  json.country_code session.country_code
  json.last_activity_at session.last_activity_at
  json.created_at session.created_at
  json.current session.current?(@current_client_id)
end
