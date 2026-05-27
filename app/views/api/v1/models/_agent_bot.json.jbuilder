json.id resource.id
json.name resource.name
json.description resource.description
json.thumbnail resource.avatar_url
json.outgoing_url resource.outgoing_url unless resource.system_bot?
json.bot_type resource.bot_type
json.bot_config resource.bot_config
json.account_id resource.account_id
json.access_token resource.access_token if resource.access_token.present? && @access_token&.scope != 'read_only'
json.secret resource.secret if !resource.system_bot? && Current.account_user&.administrator? && @access_token&.scope != 'read_only'
json.system_bot resource.system_bot?
