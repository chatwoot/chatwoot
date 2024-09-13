json.id resource.id
json.description resource.description
json.created_at resource.created_at
json.updated_at resource.updated_at
json.completed_at resource.completed_at
json.account_id resource.account_id
json.contact_id resource.contact_id
json.conversation_id resource.conversation_id
json.created_by_id resource.account_id
json.status resource.completed_at.present? ? 'resolved' : resource.conversation.status
json.action_date resource.conversation.snoozed_until || resource.conversation.updated_at
json.inbox_type resource.conversation.inbox.inbox_type
