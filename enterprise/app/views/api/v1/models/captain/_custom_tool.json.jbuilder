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
json.headers custom_tool.headers if Current.user&.administrator?
json.param_schema custom_tool.param_schema
json.enabled custom_tool.enabled
# The stored setting only. A tool with a verified email parameter needs verification without it, and saving that back would turn it on for good.
json.settings do
  json.requires_email_verification custom_tool.settings['requires_email_verification'] == true
end
json.source_metadata custom_tool.source_metadata
json.account_id custom_tool.account_id
json.assistant_id custom_tool.assistant_id
json.created_at custom_tool.created_at.to_i
json.updated_at custom_tool.updated_at.to_i
