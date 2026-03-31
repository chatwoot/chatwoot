json.id resource.id
json.name resource.name
json.description resource.description
json.thumbnail resource.avatar_url
json.outgoing_url resource.outgoing_url unless resource.system_bot?
json.bot_type resource.bot_type
json.bot_config resource.bot_config
json.assistant_config resource.assistant_config
json.agent_behavior_config resource.agent_behavior_config
json.has_openai_api_key resource.has_openai_api_key?
json.has_google_api_key resource.has_google_api_key?
json.has_pinecone_api_key resource.account&.pinecone_api_key.present?
json.account_id resource.account_id
json.access_token resource.access_token if resource.access_token.present?
json.system_bot resource.system_bot?
