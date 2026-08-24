json.id custom_tool.id
json.slug custom_tool.slug
json.title custom_tool.title
json.description custom_tool.description
json.endpoint_url custom_tool.endpoint_url
json.http_method custom_tool.http_method
json.request_template custom_tool.request_template
json.response_template custom_tool.response_template
json.auth_type custom_tool.auth_type
json.auth_config custom_tool.auth_config if Current.user&.administrator?
json.param_schema custom_tool.param_schema
json.enabled custom_tool.enabled
json.account_id custom_tool.account_id
json.created_at custom_tool.created_at.to_i
json.updated_at custom_tool.updated_at.to_i
json.source_kind custom_tool.source_kind

if custom_tool.source_catalog?
  json.provider_key custom_tool.provider_key
  json.category_key custom_tool.category_key
  json.template_key custom_tool.template_key
  json.template_version custom_tool.template_version
  json.risk_class custom_tool.risk_class
  json.connection_required custom_tool.integration_hook_id.nil?
end
