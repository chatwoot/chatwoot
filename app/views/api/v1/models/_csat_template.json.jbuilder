json.id resource.id
json.name resource.name
json.inbox_ids resource.inboxes.pluck(:id)
json.account_id resource.account_id
json.questions_count resource.questions_count
json.inboxes_names resource.inboxes.pluck(:name).join(',')
