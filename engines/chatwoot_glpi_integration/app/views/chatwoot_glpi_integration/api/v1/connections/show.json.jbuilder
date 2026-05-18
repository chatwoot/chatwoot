json.data do
  json.id @connection.id
  json.account_id @connection.account_id
  json.base_url @connection.base_url
  json.api_path @connection.api_path
  json.client_id @connection.client_id
  # client_secret intentionally not exposed
  json.scope @connection.scope
  json.default_entity_id @connection.default_entity_id
  json.default_itil_category_id @connection.default_itil_category_id
  json.default_request_type_id @connection.default_request_type_id
  json.active @connection.active
  json.last_handshake_at @connection.last_handshake_at&.iso8601
  json.webhook_url Rails.application.routes.url_helpers.webhooks_glpi_receive_path(account_id: @connection.account_id)
end
