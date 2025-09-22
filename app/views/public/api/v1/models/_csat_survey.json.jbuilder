json.id resource.id
json.csat_survey_response resource.csat_survey_response
json.display_type resource.inbox.csat_config.try(:[], 'display_type') || 'emoji'
json.content resource.inbox.csat_config.try(:[], 'message')
json.inbox_avatar_url resource.inbox.avatar_url
json.inbox_name resource.inbox.name
json.locale resource.account.locale
json.conversation_id resource.conversation_id
json.created_at resource.created_at
